#!/bin/bash
# Проверка доступности Harbor с HTTPS

set -e

K8S_NODE_IP="192.168.0.101"
HTTP_PORT="30080"
HTTPS_PORT="30444"

echo "=========================================="
echo "Проверка доступности Harbor (HTTPS)"
echo "=========================================="
echo ""

# Проверка HTTP
echo "1. Проверка HTTP (NodePort $HTTP_PORT):"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://ui.harbor.techbit.su:$HTTP_PORT/)
if [ "$HTTP_CODE" = "200" ]; then
    echo "   ✅ Harbor UI HTTP доступен (HTTP $HTTP_CODE)"
else
    echo "   ❌ Harbor UI HTTP НЕ доступен (HTTP $HTTP_CODE)"
fi

# Проверка HTTPS
echo ""
echo "2. Проверка HTTPS (NodePort $HTTPS_PORT):"
HTTPS_CODE=$(curl -k -s -o /dev/null -w "%{http_code}" https://ui.harbor.techbit.su:$HTTPS_PORT/ 2>/dev/null || echo "000")
if [ "$HTTPS_CODE" = "200" ]; then
    echo "   ✅ Harbor UI HTTPS доступен (HTTP $HTTPS_CODE)"
else
    echo "   ⚠️  Harbor UI HTTPS НЕ доступен (HTTP $HTTPS_CODE) - используйте HTTP"
fi

# Проверка Registry API
echo ""
echo "3. Проверка Registry API (HTTP):"
REGISTRY_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://harbor.techbit.su:$HTTP_PORT/v2/_catalog)
if [ "$REGISTRY_CODE" = "200" ]; then
    RESPONSE=$(curl -s http://harbor.techbit.su:$HTTP_PORT/v2/_catalog)
    echo "   ✅ Registry API доступен (HTTP $REGISTRY_CODE)"
    echo "   Ответ: $RESPONSE"
else
    echo "   ❌ Registry API НЕ доступен (HTTP $REGISTRY_CODE)"
fi

# Проверка Kubernetes ресурсов
echo ""
echo "4. Проверка Kubernetes ресурсов:"
echo "   Pods:"
kubectl get pods -n harbor --no-headers 2>/dev/null | sed 's/^/      /' || echo "      ❌ Не удалось получить статус pods"

echo ""
echo "   Ingress:"
kubectl get ingress -n harbor --no-headers 2>/dev/null | sed 's/^/      /' || echo "      ❌ Не удалось получить статус ingress"

echo ""
echo "=========================================="
echo "URL для доступа (DNS настроен):"
echo "=========================================="
echo ""
echo "HTTP (рекомендуется):"
echo "  UI:       http://ui.harbor.techbit.su:$HTTP_PORT/"
echo "  Registry: http://harbor.techbit.su:$HTTP_PORT/"
echo ""
echo "Docker команды:"
echo "  docker login harbor.techbit.su:$HTTP_PORT"
echo "  docker tag myimage:latest harbor.techbit.su:$HTTP_PORT/myimage:latest"
echo "  docker push harbor.techbit.su:$HTTP_PORT/myimage:latest"
echo ""
echo "=========================================="
