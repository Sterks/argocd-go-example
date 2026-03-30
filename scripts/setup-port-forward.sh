#!/bin/bash
# Проброс портов 80/443 на NodePort 30080/30444

set -e

echo "Настройка проброса портов..."

# Включить IP forwarding
sysctl -w net.ipv4.ip_forward=1 2>/dev/null || true

# Проброс HTTP: 80 → 30080
echo "Проброс порта 80 → 30080..."
iptables -t nat -C PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 30080 2>/dev/null || \
    iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 30080

# Проброс HTTPS: 443 → 30444
echo "Проброс порта 443 → 30444..."
iptables -t nat -C PREROUTING -p tcp --dport 443 -j REDIRECT --to-port 30444 2>/dev/null || \
    iptables -t nat -A PREROUTING -p tcp --dport 443 -j REDIRECT --to-port 30444

# Разрешить входящие соединения
iptables -C INPUT -p tcp --dport 80 -j ACCEPT 2>/dev/null || \
    iptables -A INPUT -p tcp --dport 80 -j ACCEPT

iptables -C INPUT -p tcp --dport 443 -j ACCEPT 2>/dev/null || \
    iptables -A INPUT -p tcp --dport 443 -j ACCEPT

echo ""
echo "✅ Порты проброшены!"
echo ""
echo "Проверка правил:"
iptables -t nat -L PREROUTING -n -v | grep -E "30080|30444"
echo ""
echo "Теперь доступно:"
echo "  http://harbor.techbit.su"
echo "  http://ui.harbor.techbit.su"
