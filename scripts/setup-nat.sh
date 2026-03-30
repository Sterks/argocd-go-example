#!/bin/bash
# Скрипт настройки NAT для проброса внешнего трафика на NodePort
# Внешний IP: 109.194.67.168
# NodePort HTTP: 30080
# NodePort HTTPS: 30444

set -e

# Внутренний IP узла K8s (замените на актуальный)
K8S_NODE_IP="${1:-192.168.0.101}"

echo "Настройка NAT для проброса трафика на K8s NodePort..."
echo "Внешний IP: 109.194.67.168"
echo "K8s Node IP: $K8S_NODE_IP"

# Включить IP forwarding
sysctl -w net.ipv4.ip_forward=1

# Очистить старые правила (осторожно!)
# iptables -t nat -F PREROUTING

# Проброс HTTP (порт 80 -> 30080)
iptables -t nat -A PREROUTING -d 109.194.67.168 -p tcp --dport 80 -j DNAT --to-destination $K8S_NODE_IP:30080
iptables -A FORWARD -d $K8S_NODE_IP -p tcp --dport 30080 -j ACCEPT

# Проброс HTTPS (порт 443 -> 30444)
iptables -t nat -A PREROUTING -d 109.194.67.168 -p tcp --dport 443 -j DNAT --to-destination $K8S_NODE_IP:30444
iptables -A FORWARD -d $K8S_NODE_IP -p tcp --dport 30444 -j ACCEPT

echo "NAT настроен!"
echo ""
echo "Проверка:"
echo "  curl http://harbor.techbit.su"
echo "  curl https://harbor.techbit.su"
