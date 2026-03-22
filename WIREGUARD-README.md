# WireGuard OpenWRT - Guia Completo

## Visão Geral
Este conjunto de scripts instala e configura um servidor WireGuard no seu OpenWRT para acessar sua rede local (192.168.1.0/24) remotamente via iPhone.

## Scripts Disponíveis

### 1. setup-wireguard-openwrt.sh
**Finalidade:** Instalar WireGuard e gerar chaves do servidor

**Como usar:**
```bash
opkg update && chmod +x setup-wireguard-openwrt.sh && ./setup-wireguard-openwrt.sh
```

**O que faz:**
- Instala o pacote wireguard
- Instala luci-proto-wireguard (interface web)
- Gera chaves pública/privada do servidor
- Exibe informações de conexão

### 2. setup-ddns-wireguard.sh
**Finalidade:** Configurar DuckDNS para IP dinâmico

**Como usar:**
```bash
chmod +x setup-ddns-wireguard.sh && ./setup-ddns-wireguard.sh
```

**O que faz:**
- Pergunta subdomínio DuckDNS
- Pergunta token DuckDNS
- Configura o serviço de atualização automática
- Inicia o serviço DDNS

### 3. iphone-config-wireguard.sh
**Finalidade:** Gerar configuração para o iPhone

**Como usar (no iPhone):**
1. Baixe o app WireGuard da App Store
2. Gere uma nova chave (ou use existente)
3. Copie a Public Key
4. No terminal do OpenWRT:
```bash
chmod +x iphone-config-wireguard.sh && ./iphone-config-wireguard.sh
```

**O que faz:**
- Gera arquivo .conf para o iPhone
- Configura acesso à rede 192.168.1.0/24
- Exibe configuração pronta para importar

### 4. configure-wireguard-server.sh
**Finalidade:** Completar configuração do servidor

**Como usar:**
```bash
chmod +x configure-wireguard-server.sh && ./configure-wireguard-server.sh
```

**O que faz:**
- Aplica configuração do servidor WireGuard
- Configura firewall para porta 51820
- Habilita IP forwarding
- Inicia o serviço WireGuard

## Fluxo de Instalação (Passo a Passo)

### No OpenWRT (SSH/Console):

**1. Instalar WireGuard**
```bash
./setup-wireguard-openwrt.sh
```
Anote as chaves exibidas e a Public Key do servidor

**2. Configurar DuckDNS**
```bash
./setup-ddns-wireguard.sh
```
- Subdomínio: digite seu subdomínio (ex: "minha-casa")
- Token: cole seu token DuckDNS

**3. Gerar config do iPhone**
```bash
./iphone-config-wireguard.sh
```
- Insira a Public Key do servidor (anotada no passo 1)
- Insira subdomínio DuckDNS

**4. Configurar servidor**
```bash
./configure-wireguard-server.sh
```
- Digite Private Key do servidor (anotada no passo 1)
- Digite Public Key do iPhone (anotada no passo 3)

### No iPhone:

1. Instale o app **WireGuard** da App Store
2. Importe o arquivo .conf gerado pelo script
3. Ative o túnel
4. Teste pingando 192.168.1.1

## Portas e Protocolos

- **Protocolo:** UDP
- **Porta:** 51820
- **IP do servidor:** 10.8.0.1
- **IP do iPhone:** 10.8.0.2

## Segurança

- Cada par chaves é único por cliente
- Apenas IPs autorizados (10.8.0.2/32)
- Apenas acesso à LAN especificada (192.168.1.0/24)
- Keepalive ativado para manter conexão viva

## Testes

**Do iPhone após conectar:**
```bash
# No terminal do iPhone (SSH ou app)
ping 192.168.1.1        # Gateway da casa
ping 192.168.1.100      # Qualquer dispositivo na LAN
curl http://192.168.1.1 # Acesso a interface do roteador
```

## Troubleshooting

**Problema:** iPhone não consegue conectar
- Verifique se DuckDNS está atual (teste ping do hostname)
- Confirme que porta 51820 não está bloqueada pelo ISP
- Verifique logs do WireGuard: `logread | grep wireguard`

**Problema:** Acessa a VPN mas não a LAN
- Verifique firewall: `iptables -L -n -t nat`
- Confirme configuração de forwarding

**Problema:** IP muda e conexão para
- O DuckDNS deve atualizar automaticamente
- Reinicie o serviço: `/etc/init.d/ddns restart`

## Variáveis de Ambiente (Opcional)

Você pode configurar variáveis antes de rodar:
```bash
export WG_DDNS_SUBDOMAIN="minha-casa"
export WG_DDNS_TOKEN="seu-token-aqui"
./setup-ddns-wireguard.sh
```

## Arquitetura de Rede

```
Internet
  │
  ├─ DuckDNS (atualiza IP dinâmico)
  │
  └─ OpenWRT:10.8.0.1 (WireGuard Server)
         │
         ├─ LAN (192.168.1.0/24)
         │   ├─ Router, PC, Printer, etc
         │
         └─ Túnel WireGuard (10.8.0.0/24)
             └─ iPhone:10.8.0.2
```

---

**Autor:** Script gerado para OpenWRT + WireGuard
**Data:** 2026-03-22
