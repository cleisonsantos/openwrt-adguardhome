#!/bin/bash
set -eu

echo "=========================================="
echo "  Gerar Config do WireGuard para iPhone  "
echo "=========================================="

echo ""
echo "Este script gera o arquivo de configuração (.conf) para seu iPhone,"
echo "já configurado para acessar sua rede local (192.168.1.0/24)"
echo ""

read -p "Insira o Public Key do servidor OpenWRT: " WG_SERVER_PUB
read -p "Insira o Subdomínio DuckDNS (ex: minha-casa): " WG_DDNS_SUBDOM
read -s -p "Insira a Private Key do iPhone (ou pressione Enter para gerar nova): " WG_CLIENT_PRIV

echo ""

if [ -z "$WG_CLIENT_PRIV" ]; then
    echo "Gerando nova chave para iPhone..."
    wg genkey | tee /tmp/wg-iphone-key
    WG_CLIENT_PRIV=$(cat /tmp/wg-iphone-key)
    WG_CLIENT_PUB=$(echo "$WG_CLIENT_PRIV" | wg pubkey)
    echo ""
    echo "Sua chave foi gerada:"
    echo "Private Key: $WG_CLIENT_PRIV"
    echo "Public Key: $WG_CLIENT_PUB"
    echo ""
    echo "COPIE a Public Key acima e envie para o OpenWRT (no Network > WireGuard)"
else
    echo "Private Key recebida (não será exibida)"
fi

echo ""
echo "Gerando arquivo de configuração..."

cat > /tmp/iphone-wireguard.conf <<EOF
[Interface]
Address = 10.8.0.2/24
PrivateKey = $WG_CLIENT_PRIV
DNS = 192.168.1.1

[Peer]
PublicKey = $WG_SERVER_PUB
Endpoint = ${WG_DDNS_SUBDOM}.duckdns.org:51820
AllowedIPs = 192.168.1.0/24,10.8.0.0/24
PersistentKeepalive = 25
EOF

echo ""
echo "=========================================="
echo "  Config Gerada!                       "
echo "=========================================="
echo ""
echo "Arquivo salvo em: /tmp/iphone-wireguard.conf"
echo ""
echo "Para transferir para o iPhone:"
echo "  A) Exportar o arquivo e importar pelo app WireGuard"
echo "  B) Copiar o conteúdo via AirDrop/Email/Google Drive"
echo ""
echo "Conteúdo completo:"
echo ""
cat /tmp/iphone-wireguard.conf
echo ""
echo "=========================================="
echo "  Pronto! Abra o app WireGuard no iPhone "
echo "  e selecione 'Importar perfil a partir de arquivo'"
echo "=========================================="
