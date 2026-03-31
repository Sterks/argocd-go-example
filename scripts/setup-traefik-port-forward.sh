#!/bin/bash
# Скрипт для перенаправления портов 80/443 на NodePort Traefik
# Выполнить на каждой ноде кластера

# Перенаправление HTTP 80 -> 30080
iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 30080

# Перенаправление HTTPS 443 -> 30444
iptables -t nat -A PREROUTING -p tcp --dport 443 -j REDIRECT --to-port 30444

# Сохранение правил (для Ubuntu/Debian)
# iptables-save > /etc/iptables/rules.v4

echo "Port forwarding configured:"
echo "  80 -> 30080 (HTTP)"
echo "  443 -> 30444 (HTTPS)"
