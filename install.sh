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

if [ "$1" = "--finalize" ]; then
    # Wait until AdGuard Home is responding on port 53
    tries=30
    while [ "$tries" -gt 0 ]; do
        if nslookup -timeout=2 openwrt.org 127.0.0.1 >/dev/null 2>&1; then
            break
        fi
        tries=$((tries - 1))
        sleep 1
    done

    if [ "$tries" -eq 0 ]; then
        echo "ERROR: AdGuard Home ainda nao responde em 127.0.0.1:53"
        echo "Configure o AdGuard Home e tente novamente."
        exit 1
    fi

    # Set AdGuard Home as upstream DNS for dnsmasq (so the router itself can resolve domains)
    uci -q del dhcp.@dnsmasq[0].server
    uci add_list dhcp.@dnsmasq[0].server="127.0.0.1:53"
    uci commit dhcp
    service dnsmasq restart

    echo "DNS do roteador agora aponta para o AdGuard Home."
    exit 0
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
# IMPORTANT: Não configuramos o dnsmasq para usar 127.0.0.1:53 ainda
# Isso será feito após o AdGuard Home estar configurado e respondendo na porta 53
# Para evitar que o roteador pare de resolver DNS durante a configuração inicial

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

echo ""
echo "========================================"
echo "AdGuard Home instalado com sucesso!"
echo "========================================"
echo ""
echo "IMPORTANTE: O AdGuard Home precisa ser configurado antes de ativar o DNS."
echo ""
echo "Proximos passos:"
echo "1. Acesse a interface web em: http://${NET_ADDR}:8080"
echo "2. Configure o AdGuard Home (defina porta 53 para DNS)"
echo "3. Adicione upstream DNS (ex: https://dns10.quad9.net/dns-query)"
echo "4. Execute: ./finalize-install.sh"
echo ""
echo "O dnsmasq foi configurado para nao vazar consultas DNS para o ISP."
echo "Clientes DHCP receberao ${NET_ADDR} como DNS."
echo ""
echo "Para verificar se o AdGuard esta respondendo:"
echo "  nslookup google.com 127.0.0.1"
echo ""

exit 0
