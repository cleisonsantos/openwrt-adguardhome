#!/bin/bash
set -eu

echo "=========================================="
echo "  Instalar WireGuard no OpenWRT           "
echo "=========================================="

# --- CONFIGURAVEIS ---
WG_DDNS_HOST="${WG_DDNS_HOST:-}"
WG_DDNS_TOKEN="${WG_DDNS_TOKEN:-}"
WG_DDNS_SUBDOMAIN="${WG_DDNS_SUBDOMAIN:-}"
WG_TUN_NETWORK="10.8.0.0/24"
WG_SERVER_IP="10.8.0.1"
WG_CLIENT_IP="10.8.0.2"
WG_PORT="51820"
WG_LAN_NET="192.168.1.0/24"

# 1. Atualizar e instalar
echo ""
echo "[1/4] Atualizando lista de pacotes..."
opkg update

echo ""
echo "[2/4] Instalando WireGuard..."
opkg install wireguard

# Tentar instalar interface web
echo ""
echo "[3/4] Instalando interface web (Luci)..."
opkg install luci-proto-wireguard 2>/dev/null || echo "luci-proto-wireguard não disponivel (não configurado no repositório)"

echo ""
echo "[4/4] Gerando chaves do servidor WireGuard..."
/usr/lib/wireguard/wg-genkey | tee /tmp/wg-server.key
wg pubkey < /tmp/wg-server.key > /tmp/wg-server.pub

echo ""
echo "=========================================="
echo "  Pensamento do servidor WireGuard       "
echo "=========================================="
echo ""
echo "Private Key (Servidor):"
cat /tmp/wg-server.key
echo ""
echo "Public Key (Servidor):"
cat /tmp/wg-server.pub
echo ""
echo "Endpoint com DDNS:"
if [ -n "$WG_DDNS_SUBDOMAIN" ] && [ -n "$WG_DDNS_TOKEN" ]; then
    echo "  ${WG_DDNS_SUBDOMAIN}.duckdns.org:$WG_PORT"
else
    echo "  <SeuHostname.duckdns.org>:$WG_PORT"
    echo "  Subdomínio: ${WG_DDNS_SUBDOMAIN:-nao definido}"
    echo "  Token DDNS: ${WG_DDNS_TOKEN:-nãodificado ainda}"
fi
echo ""
echo "Rede interna a acessar:"
echo "  ${WG_LAN_NET}"
echo "=========================================="
echo ""
echo "PRÓXIMOS PASSOS:"
echo ""
echo "1. No iPhone: App WireGuard, criar nova entrada, importar config"
echo "2. Copiar o Public Key do iPhone e enviar para o OpenWRT"
echo "3. Em Network > WireGuard, adicionar peer com a chave do iPhone"
echo "4. Usar DuckDNS updater para atualizar o endpoint automaticamente"
echo ""
echo "Para configurar o DDNS, use: setup-ddns.sh"
echo ""
