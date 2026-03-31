#!/bin/bash
# Скрипт для перенаправления портов 80/443 на NodePort Traefik
# Выполнить на каждой ноде кластера

set -e

echo "Configuring port forwarding for Traefik..."

# Удаляем старые правила если существуют
iptables -t nat -D PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 30080 2>/dev/null || true
iptables -t nat -D PREROUTING -p tcp --dport 443 -j REDIRECT --to-port 30444 2>/dev/null || true

# Добавляем правила перенаправления
iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 30080
iptables -t nat -A PREROUTING -p tcp --dport 443 -j REDIRECT --to-port 30444

# Сохраняем правила (для Ubuntu/Debian с iptables-persistent)
if command -v iptables-save &> /dev/null; then
    if [ -d /etc/iptables ]; then
        iptables-save > /etc/iptables/rules.v4
        echo "Rules saved to /etc/iptables/rules.v4"
    fi
fi

echo ""
echo "Port forwarding configured successfully:"
echo "  80  -> 30080 (HTTP)"
echo "  443 -> 30444 (HTTPS)"
echo ""
echo "Vault UI will be available at:"
echo "  http://vault.techbit.su/ui/vault"
echo "  https://vault.techbit.su/ui/vault"
