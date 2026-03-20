#!/bin/sh

# Stop and disable AdGuard Home service
service adguardhome stop
service adguardhome disable

# Remove AdGuard Home package
if command -v apk >/dev/null 2>&1; then
    apk del adguardhome
else
    opkg remove adguardhome
fi

# 1. Reverts AdGuard Home configuration and resets settings to default.
# 2. Enable rebind protection.
# 3. Remove DHCP options for IPv4 and IPv6
uci -q delete dhcp.@dnsmasq[0].noresolv
uci -q delete dhcp.@dnsmasq[0].cachesize
uci set dhcp.@dnsmasq[0].rebind_protection='1'
uci -q delete dhcp.@dnsmasq[0].server
# Restore port to default (empty = port 53)
uci set dhcp.@dnsmasq[0].port=""

# Get original NET_ADDR6 for proper cleanup
dev=$(ifstatus lan | grep '"device"' | awk '{ print $2 }' | sed 's/[",]//g')
NET_ADDR6=$(/sbin/ip -o -6 addr list $dev scope global | awk '$4 ~ /^fd|^fc/ { split($4, ip_addr, "/"); print ip_addr[1]; exit }')

# Remove DHCP options and DNS (using del_list for list values)
uci -q del dhcp.lan.dhcp_option
uci -q del_list dhcp.lan.dns="$NET_ADDR6"

# Remove firewall rule for DNS interception
uci -q del firewall.adguardhome_dns_53

# Network Configuration
# Disable peer/ISP DNS
uci set network.wan.peerdns="0"
uci set network.wan6.peerdns="0"

# Configure DNS provider to Google DNS
uci -q delete network.wan.dns
uci add_list network.wan.dns="8.8.8.8"
uci add_list network.wan.dns="8.8.4.4"

# Configure IPv6 DNS provider to Google DNS
uci -q delete network.wan6.dns
uci add_list network.wan6.dns="2001:4860:4860::8888"
uci add_list network.wan6.dns="2001:4860:4860::8844"

# Save and apply
uci commit dhcp
uci commit firewall
uci commit network
/etc/init.d/network restart
/etc/init.d/dnsmasq restart
/etc/init.d/odhcpd restart
/etc/init.d/firewall restart
