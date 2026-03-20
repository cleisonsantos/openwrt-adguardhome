#!/bin/sh

# Detect package manager (apk for OpenWrt 25.12+, opkg otherwise)
if command -v apk >/dev/null 2>&1; then
    PKG_MGR="apk"
elif command -v opkg >/dev/null 2>&1; then
    PKG_MGR="opkg"
else
    echo "ERROR: Neither apk nor opkg found"
    exit 1
fi

# Install AdGuard Home
if [ "$PKG_MGR" = "apk" ]; then
    apk update
    apk add adguardhome
else
    opkg update
    opkg install adguardhome
fi

# Get the first IPv4 and IPv6 Address of the router LAN interface
dev=$(ifstatus lan | grep '"device"' | awk '{ print $2 }' | sed 's/[",]//g')
NET_ADDR=$(/sbin/ip -o -4 addr list $dev | awk 'NR==1{ split($4, ip_addr, "/"); print ip_addr[1]; exit }')
NET_ADDR6=$(/sbin/ip -o -6 addr list $dev scope global | awk '$4 ~ /^fd|^fc/ { split($4, ip_addr, "/"); print ip_addr[1]; exit }')
echo "Router IPv4 : ""${NET_ADDR}"
echo "Router IPv6 : ""${NET_ADDR6}"

# 1. Move dnsmasq to port 54.
# 2. Set local domain to "lan".
# 3. Add local '/lan/' to make sure all queries *.lan are resolved in dnsmasq;
# 4. Add expandhosts '1' to make sure non-expanded hosts are expanded to ".lan";
# 5. Disable dnsmasq cache size as it will only provide PTR/rDNS info, making sure queries are always up to date (even if a device internal IP change after a DHCP lease renew).
# 6. Disable reading /tmp/resolv.conf.d/resolv.conf.auto file (which are your ISP nameservers by default), you don't want to leak any queries to your ISP.
# 7. Delete all forwarding servers from dnsmasq config.
uci set dhcp.@dnsmasq[0].port="54"
uci set dhcp.@dnsmasq[0].domain="lan"
uci set dhcp.@dnsmasq[0].local="/lan/"
uci set dhcp.@dnsmasq[0].expandhosts="1"
uci set dhcp.@dnsmasq[0].cachesize="0"
uci set dhcp.@dnsmasq[0].noresolv="1"
uci -q del dhcp.@dnsmasq[0].server
# Set AdGuard Home as upstream DNS for dnsmasq (so the router itself can resolve domains)
uci add_list dhcp.@dnsmasq[0].server="127.0.0.1:53"

# Delete existing config ready to install new options.
uci -q del dhcp.lan.dhcp_option
uci -q del dhcp.lan.dns

# DHCP option 3: Specifies the gateway the DHCP server should send to DHCP clients.
uci add_list dhcp.lan.dhcp_option='3,'"${NET_ADDR}"

# DHCP option 6: Specifies the DNS server the DHCP server should send to DHCP clients.
uci add_list dhcp.lan.dhcp_option='6,'"${NET_ADDR}"

# DHCP option 15: Specifies the domain suffix the DHCP server should send to DHCP clients.
uci add_list dhcp.lan.dhcp_option='15,'"lan"

# Set IPv6 Announced DNS
uci add_list dhcp.lan.dns="$NET_ADDR6"

# Add firewall rules for DNS interception (redirect LAN DNS queries to AdGuard Home)
# Remove existing rule if present to avoid duplicates
uci -q del firewall.adguardhome_dns_53

cat >> /etc/config/firewall << 'EOF'

config redirect 'adguardhome_dns_53'
	option src 'lan'
	option proto 'tcp udp'
	option src_dport '53'
	option target 'DNAT'
	option name 'Adguard Home DNS'
	option dest 'lan'
	option dest_port '53'
EOF

uci commit dhcp
uci commit firewall
service dnsmasq restart
service odhcpd restart
service firewall restart

# Enable and start AdGuard Home
service adguardhome enable
service adguardhome start

exit 0
