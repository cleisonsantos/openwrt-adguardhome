#!/bin/sh

# ============================================
# Configuração DDNS para DuckDNS
# ============================================
# SUBSTITUA "SEU_TOKEN_DUCKDNS" pelo seu token
# ============================================

DUCKDNS_TOKEN="SEU_TOKEN_DUCKDNS"
DUCKDNS_DOMAIN="cleison"
DUCKDNS_USERNAME="cleison"

echo "=== Configurando DDNS para ${DUCKDNS_DOMAIN}.duckdns.org ==="

# Atualizar /etc/config/ddns
cat > /etc/config/ddns << EOF
config service "${DUCKDNS_DOMAIN}"
        option enabled          "1"
        option domain           "${DUCKDNS_DOMAIN}.duckdns.org"
        option username         "${DUCKDNS_USERNAME}"
        option password         "${DUCKDNS_TOKEN}"
        option ip_source        "network"
        option ip_network       "wan"
        option force_interval   "72"
        option force_unit       "hours"
        option check_interval   "10"
        option check_unit       "minutes"
        option update_url       "http://www.duckdns.org/update?domains=${DUCKDNS_USERNAME}&token=${DUCKDNS_TOKEN}&ip=[IP]"
EOF

echo "Configuração DDNS criada em /etc/config/ddns"

# Se quiser usar HTTPS com CA bundle, instalar curl e certificado
echo "Instalando curl e CA bundle para HTTPS..."
opkg update
opkg install curl

mkdir -p /etc/ssl/certs
curl -k https://certs.secureserver.net/repository/sf_bundle-g2.crt > /etc/ssl/certs/ca-bundle.pem 2>/dev/null

# Habilitar HTTPS no DDNS (opcional - remova os comentários se quiser)
sed -i 's/#option use_https/option use_https/' /etc/config/ddns
sed -i 's/#option cacert/option cacert/' /etc/config/ddns

# Iniciar DDNS
echo "Iniciando serviço DDNS..."
. /usr/lib/ddns/dynamic_dns_functions.sh
start_daemon_for_all_ddns_sections "wan"

echo "=== DDNS configurado com sucesso! ==="
echo "Teste manual: /usr/lib/ddns/dynamic_dns_updater.sh ${DUCKDNS_DOMAIN}"
