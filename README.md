# OpenWrt + AdGuard Home

Scripts para instalação e configuração do AdGuard Home no OpenWrt com suporte a DNS criptografado (DoH/DoT) via Let's Encrypt.

## Pré-requisitos

- OpenWrt 21.02 ou superior
- Acesso SSH ao roteador
- Domínio DuckDNS (ex: `cleison.duckdns.org`)
- Token API do DuckDNS (obter em [duckdns.org](https://www.duckdns.org/account))

## Estrutura dos Arquivos

| Arquivo | Descrição |
|---------|-----------|
| `install.sh` | Instala o AdGuard Home, configura dnsmasq e firewall |
| `uninstall.sh` | Remove o AdGuard Home e restaura configurações originais |
| `setup-ddns.sh` | Configura o DDNS para atualizar o DuckDNS |
| `ssl-setup.sh` | Gera certificado Let's Encrypt via DNS Challenge |
| `adguardhome.txt` | Documentação de referência |

## Instalação

### 1. Clone o repositório no OpenWrt

```bash
cd /root
git clone https://github.com/cleisonsantos/openwrt-adguardhome.git
cd openwrt-adguardhome
```

### 2. Execute o script de instalação

```bash
chmod +x install.sh
./install.sh
```

Este script:
- Instala o pacote `adguardhome`
- Move o dnsmasq para a porta 54
- Configura o DHCP para anunciar o AdGuard como DNS
- Cria regras de firewall para interceptar DNS
- Inicia o serviço AdGuard Home

### 3. Configure o DDNS (DuckDNS)

Edite o arquivo `setup-ddns.sh` e substitua `SEU_TOKEN_DUCKDNS` pelo seu token:

```bash
nano setup-ddns.sh
```

Execute:

```bash
chmod +x setup-ddns.sh
./setup-ddns.sh
```

### 4. Configure o HTTPS/DoH/DoT

Edite o arquivo `ssl-setup.sh` e substitua `SEU_TOKEN_DUCKDNS`:

```bash
nano ssl-setup.sh
```

Execute:

```bash
chmod +x ssl-setup.sh
./ssl-setup.sh
```

### 5. Configure o AdGuard Home via Web Interface

1. Acesse a interface web em `http://SEU_IP_ROTEADOR:8080`
2. Vá em **Settings → DNS Settings**
3. Configure **Private reverse DNS servers** como `127.0.0.1:54`
4. Marque as opções:
   - "Use private reverse DNS resolvers"
   - "Enable reverse resolving of clients' IP addresses"
5. Vá em **Settings → TLS**
6. Habilite **Encryption** e configure:
   - **Server name**: `cleison.duckdns.org` (seu domínio)
   - **Certificate chain**: `/etc/adguardhome/cert.pem`
   - **Private key**: `/etc/adguardhome/key.pem`
   - **DNS-over-HTTPS**: Habilitado (porta 443)
   - **DNS-over-TLS**: Habilitado (porta 853)

### 6. Regras de Firewall

As regras já são adicionadas pelo `install.sh`. Para verificar:

```bash
uci show firewall | grep adguardhome
```

## Desinstalação

```bash
chmod +x uninstall.sh
./uninstall.sh
```

## Upstream DNS Padrão

O AdGuard Home vem configurado com **Quad9** (`https://dns10.quad9.net/dns-query`) como upstream DNS padrão.

## Portas Utilizadas

| Porta | Serviço | Descrição |
|-------|---------|-----------|
| 53 | DNS | Servidor DNS do AdGuard |
| 54 | DNS | dnsmasq (PTR reverso) |
| 80 | HTTP | ACME HTTP challenge (temporário) |
| 443 | HTTPS/DoH | Web UI e DoH |
| 8080 | HTTP | Web UI Admin |
| 853 | DoT | DNS-over-TLS |

## Troubleshooting

### Verificar logs do AdGuard

```bash
logread -e AdGuardHome
```

### Verificar status do serviço

```bash
service adguardhome status
```

### Reiniciar o serviço

```bash
service adguardhome restart
```

### Testar DNS

```bash
nslookup google.com 127.0.0.1
```

### Testar DoT

```bash
echo "tls(dot):dns10.quad9.net" | nslookup -timeout=2 -
```

## Referências

- [AdGuard Home](https://adguard.com/en/adguard-home/overview.html)
- [OpenWrt Wiki - AdGuard Home](https://openwrt.org/docs/guide-user/services/dns/adguard-home)
- [DuckDNS](https://www.duckdns.org/)
- [Let's Encrypt](https://letsencrypt.org/)
