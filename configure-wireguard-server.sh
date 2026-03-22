#!/bin/bash
set -eu

echo "=========================================="
echo "  Configurar Servidor WireGuard          "
echo "=========================================="

echo ""
echo "Este script completa a configuração do servidor WireGuard"
echo "e configura o firewall do OpenWRT"
echo ""

echo "[1/4] Criando configuração do WireGuard Server..."

read -p "Private Key do Servidor: " WG_SERVER_PRIV
read -p "Public Key do iPhone (Peer): " WG_CLIENT_PUB

# Definir configurações
WG_DDNS_HOST="${WG_DDNS_SUBDOMAIN:-minha-casa}.duckdns.org"
WG_TUN_NETWORK="10.8.0.0/24"
WG_SERVER_IP="10.8.0.1"
WG_PORT="51820"
WG_LAN_NET="192.168.1.0/24"

# Criar config do WireGuard
mkdir -p /etc/config
mkdir -p /etc/wireguard

cat > /etc/config/wireguard <<EOF
config interface 'wg0'
    option proto 'wireguard'
    option private_key '${WG_SERVER_PRIV}'
    option listen_port ${WG_PORT}
    option address '10.8.0.1/24'
    option mtu '1420'
    option dns '192.168.1.1,8.8.8.8'
    option post_up 'iptables -t nat -A POSTROUTING -o pppoe-wan -j MASQUERADE; iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -A FORWARD -i %i -o %i -p udp --dport 51820 -j ACCEPT'
    option post_down 'iptables -t nat -D POSTROUTING -o pppoe-wan -j MASQUERADE; iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT'

config peer 'iphone'
    option public_key '${WG_CLIENT_PUB}'
    option allowed_ips '10.8.0.2/32,192.168.1.0/24'
    option preshare_key ''
    option endpoint_host '${WG_DDNS_HOST}'
    option endpoint_port '51820'
    option persistent_keepalive '25'
    option route_allowed_routes '1'
EOF

# Configurar firewall para permitir porta 51820
echo ""
echo "[2/4] Configurando firewall..."

# Verificar se o zone wan existe
if ! grep -q "option name 'wan'" /etc/config/firewall 2>/dev/null; then
    echo "Zone 'wan' não encontrada, criando..."
    cat >> /etc/config/firewall <<EOF

config zone
    option name 'wan'
    option proto 'udp'
    option input 'REJECT'
    option output 'ACCEPT'
    option forward 'REJECT'
EOF
fi

# Adicionar regra de firewall para WireGuard
firewall_add_rule_firewall "lan" "input" "allow_wg_in" "local" "10.8.0.0/24" "udp" "51820" "accept"

# Configurar o forwarding
sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf

echo ""
echo "[3/4] Iniciando serviços..."

# Iniciar o WireGuard
/etc/init.d/wireguard enable
/etc/init.d/wireguard start

# Reiniciar o firewall
/etc/init.d/firewall restart

echo ""
echo "[4/4] Verificando status..."

echo ""
echo "Status do WireGuard:"
wgshow

echo ""
echo "=========================================="
echo "  WireGuard Configurado!                "
echo "=========================================="
echo ""
echo "Servidor WireGuard no OpenWRT:"
echo "  Endereço: 10.8.0.1"
echo "  Porta: $WG_PORT"
echo "  Host: $WG_DDNS_HOST"
echo ""
echo "Peer (iPhone):"
echo "  IP: 10.8.0.2"
echo "  Public Key: $WG_CLIENT_PUB"
echo ""
echo "Seu iPhone já deve poder acessar a rede 192.168.1.0/24!"
echo ""
echo "Para testar: ative o túnel no iPhone e tente pingar 192.168.1.1"
echo ""
