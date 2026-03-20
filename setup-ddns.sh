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

# Detectar package manager (apk for OpenWrt 25.12+, opkg otherwise)
if command -v apk >/dev/null 2>&1; then
    PKG_MGR="apk"
    echo "Detectado: apk"
elif command -v opkg >/dev/null 2>&1; then
    PKG_MGR="opkg"
    echo "Detectado: opkg"
else
    echo "ERROR: Nem apk nem opkg encontrado"
    exit 1
fi

# Instalar ddns-scripts
echo "Instalando ddns-scripts..."
if [ "$PKG_MGR" = "apk" ]; then
    apk update
    apk add ddns-scripts
else
    opkg update
    opkg install ddns-scripts
fi

# Atualizar /etc/config/ddns
# Nota: password fica VAZIO pois o token vai na URL (ddns-scripts substitui [PASSWORD])
cat > /etc/config/ddns << EOF
config service "${DUCKDNS_DOMAIN}"
        option enabled          "1"
        option domain           "${DUCKDNS_DOMAIN}.duckdns.org"
        option username         "${DUCKDNS_USERNAME}"
        option password         ""
        option ip_source        "network"
        option ip_network       "wan"
        option force_interval   "72"
        option force_unit       "hours"
        option check_interval   "10"
        option check_unit       "minutes"
        option update_url       "http://www.duckdns.org/update?domains=[USERNAME]&token=[PASSWORD]&ip=[IP]"
EOF

echo "Configuração DDNS criada em /etc/config/ddns"

# Iniciar DDNS via init.d (assíncrono, não trava o script)
echo "Iniciando serviço DDNS..."
/etc/init.d/ddns enable
/etc/init.d/ddns start

echo "=== DDNS configurado com sucesso! ==="
echo ""
echo "Verificar status:"
echo "  /etc/init.d/ddns status"
echo "  logread -e ddns"
echo ""
echo "Teste manual:"
echo "  /usr/lib/ddns/dynamic_dns_updater.sh ${DUCKDNS_DOMAIN}"
echo ""
echo "---"
echo "Para habilitar HTTPS (opcional):"
echo "  opkg install curl"
echo "  mkdir -p /etc/ssl/certs"
echo "  curl -k https://certs.secureserver.net/repository/sf_bundle-g2.crt > /etc/ssl/certs/ca-bundle.pem"
echo "  Edite /etc/config/ddns e descomente as linhas use_https e cacert"
