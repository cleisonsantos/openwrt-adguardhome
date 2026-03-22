#!/bin/bash
set -eu

echo "=========================================="
echo "  Configurar DuckDNS no OpenWRT          "
echo "=========================================="

echo ""
echo "Este script configura o update automático do IP no DuckDNS"
echo ""

# Perguntar subdomínio e token
read -p "Subdomínio (ex: minha-casa): " WG_DDNS_SUBDOMAIN
read -sp "Token DuckDNS (será exibido em texto): " WG_DDNS_TOKEN
echo ""

if [ -z "$WG_DDNS_SUBDOMAIN" ] || [ -z "$WG_DDNS_TOKEN" ]; then
    echo "Erro: subdomínio e token são obrigatórios!"
    exit 1
fi

echo ""
echo "[1/3] Atualizando pacotes..."
opkg update

echo ""
echo "[2/3] Instalando ddns-scripts e duckdns..."
opkg install ddns-scripts ddns-scripts-duckdns
opkg install wget openssl

echo ""
echo "[3/3] Criando configurações do DuckDNS..."

# Criar config do DDNS para o OpenWRT
mkdir -p /etc/config
mkdir -p /etc/hotplug.d/iface

cat > /etc/config/ddns <<EOF
config global
    option check_host_ip '0'
    option use_https '0'
    option protocol 'dyndns'
    option ssl_verify '0'

config service
    option enabled '1'
    option force_interval '60'
    option force_unit 'seconds'
    option interface 'wan'
    option ip_address 'ip'
    option ip_type 'IPv4'
    option lookup_host '${WG_DDNS_SUBDOMAIN}.duckdns.org'
    option service_name 'duckdns'
    option update_url 'https://www.duckdns.org/update?domains=${WG_DDNS_SUBDOMAIN}&token=${WG_DDNS_TOKEN}&ip='
    option username ''
    option password '${WG_DDNS_TOKEN}'

config domain
    option enabled '1'
    option interface 'wan'
    option domain '${WG_DDNS_SUBDOMAIN}.duckdns.org'
    update_url 'https://www.duckdns.org/update?domains=${WG_DDNS_SUBDOMAIN}&token=${WG_DDNS_TOKEN}&ip='\

EOF

echo ""
echo "=========================================="
echo "  DuckDNS configurado!                  "
echo "=========================================="
echo ""
echo "Hostname: ${WG_DDNS_SUBDOMAIN}.duckdns.org"
echo ""
echo "Iniciando o serviço..."
/etc/init.d/ddns start
echo ""
echo "O IP será atualizado automaticamente!"
echo ""
echo "Próximo passo: use setup-wireguard-openwrt.sh"
echo ""
