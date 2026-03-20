#!/bin/sh

# ============================================
# Configuração Let's Encrypt via acme.sh
# DNS Challenge com DuckDNS
# ============================================
# SUBSTITUA "SEU_TOKEN_DUCKDNS" pelo seu token
# ============================================

DUCKDNS_TOKEN="SEU_TOKEN_DUCKDNS"
DOMAIN="cleison.duckdns.org"
CERT_DIR="/etc/adguardhome"

echo "=== Gerando certificado Let's Encrypt para ${DOMAIN} ==="

# Verificar se acme.sh está instalado
if ! command -v acme.sh >/dev/null 2>&1; then
    echo "Instalando acme.sh..."
    opkg update
    opkg install acme.sh
fi

# Criar diretório para certificados
mkdir -p "$CERT_DIR"

# Configurar token do DuckDNS para DNS challenge
export DuckDNS_Token="$DUCKDNS_TOKEN"

# Gerar certificado via DNS challenge
echo "Gerando certificado via DNS Challenge (DuckDNS)..."
acme.sh --issue --dns dns_duckdns -d "$DOMAIN" --keylength 2048

if [ $? -eq 0 ]; then
    echo "Certificado gerado com sucesso!"
    
    # Instalar certificados
    echo "Instalando certificados em ${CERT_DIR}..."
    acme.sh --install-cert -d "$DOMAIN" \
        --cert-file "$CERT_DIR/cert.pem" \
        --key-file "$CERT_DIR/key.pem" \
        --reloadcmd "chmod 644 $CERT_DIR/cert.pem && chmod 600 $CERT_DIR/key.pem"
    
    # Ajustar permissões
    chmod 644 "$CERT_DIR/cert.pem"
    chmod 600 "$CERT_DIR/key.pem"
    
    echo "=== Certificados instalados ==="
    echo "  Cert: ${CERT_DIR}/cert.pem"
    echo "  Key:  ${CERT_DIR}/key.pem"
    echo ""
    echo "Agora configure o AdGuard Home via Web UI:"
    echo "  Settings > TLS > Enable Encryption"
    echo "  Server name: ${DOMAIN}"
    echo "  Certificate chain: ${CERT_DIR}/cert.pem"
    echo "  Private key: ${CERT_DIR}/key.pem"
    echo "  DNS-over-HTTPS: 443"
    echo "  DNS-over-TLS: 853"
else
    echo "ERRO: Falha ao gerar certificado. Verifique:"
    echo "  1. Token DuckDNS está correto"
    echo "  2. Domínio ${DOMAIN} existe no DuckDNS"
    echo "  3. Token tem permissões corretas"
    exit 1
fi
