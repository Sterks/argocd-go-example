#!/bin/bash
# Проверка доступности Harbor и настройки сети

set -e

K8S_NODE_IP="192.168.0.101"
EXTERNAL_IP="109.194.67.168"

echo "=========================================="
echo "Проверка доступности Harbor"
echo "=========================================="

echo ""
echo "1. Проверка Traefik NodePort (локально):"
if curl -s -o /dev/null -w "%{http_code}" -H "Host: harbor.techbit.su" http://$K8S_NODE_IP:30080/v2/_catalog | grep -q 200; then
    echo "   ✅ Traefik NodePort работает (HTTP 200)"
else
    echo "   ❌ Traefik NodePort НЕ работает"
    exit 1
fi

echo ""
echo "2. Проверка Harbor API:"
RESPONSE=$(curl -s -H "Host: harbor.techbit.su" http://$K8S_NODE_IP:30080/v2/_catalog)
echo "   Ответ: $RESPONSE"

echo ""
echo "3. Проверка Harbor UI:"
if curl -s -o /dev/null -w "%{http_code}" -H "Host: ui.harbor.techbit.su" http://$K8S_NODE_IP:30080/ | grep -q 200; then
    echo "   ✅ Harbor UI доступен (HTTP 200)"
else
    echo "   ❌ Harbor UI НЕ доступен"
fi

echo ""
echo "=========================================="
echo "Инструкция по настройке доступа извне:"
echo "=========================================="
echo ""
echo "На роутере с внешним IP $EXTERNAL_IP настройте NAT:"
echo ""
echo "  Порт WAN 80   →  $K8S_NODE_IP:30080 (HTTP)"
echo "  Порт WAN 443  →  $K8S_NODE_IP:30444 (HTTPS)"
echo ""
echo "После настройки проверьте:"
echo "  curl http://$EXTERNAL_IP/ -H 'Host: harbor.techbit.su'"
echo "  curl http://$EXTERNAL_IP/ -H 'Host: ui.harbor.techbit.su'"
echo ""
echo "Или откройте в браузере:"
echo "  http://harbor.techbit.su"
echo "  http://ui.harbor.techbit.su"
echo ""
echo "=========================================="
echo "Для локального доступа добавьте в /etc/hosts:"
echo "=========================================="
echo ""
echo "sudo bash -c 'echo \"$K8S_NODE_IP harbor.techbit.su\" >> /etc/hosts'"
echo "sudo bash -c 'echo \"$K8S_NODE_IP ui.harbor.techbit.su\" >> /etc/hosts'"
echo ""
