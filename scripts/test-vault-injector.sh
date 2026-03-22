#!/bin/bash
# Скрипт для тестирования Vault Agent Injector

set -e

NAMESPACE="argocd-go-example"
VAULT_NAMESPACE="vault"

echo "=== 📋 Vault Agent Injector Test Suite ==="
echo ""

# 1. Проверка Vault Agent Injector
echo "1️⃣  Проверка Vault Agent Injector..."
kubectl get pods -n $VAULT_NAMESPACE -l app.kubernetes.io/name=vault-agent-injector
echo ""

# 2. Проверка ServiceAccount
echo "2️⃣  Проверка ServiceAccount..."
kubectl get sa vault-auth -n $NAMESPACE
echo ""

# 3. Проверка RBAC
echo "3️⃣  Проверка RBAC..."
kubectl get clusterrolebinding vault-auth-delegator
echo ""

# 4. Проверка политики Vault
echo "4️⃣  Проверка политики Vault..."
kubectl exec -it vault-0 -n $VAULT_NAMESPACE -- vault policy read go-app-policy
echo ""

# 5. Проверка роли Kubernetes auth
echo "5️⃣  Проверка роли Kubernetes auth..."
kubectl exec -it vault-0 -n $VAULT_NAMESPACE -- vault read auth/kubernetes/role/go-app-role
echo ""

# 6. Проверка секрета в Vault
echo "6️⃣  Чтение секрета из Vault..."
kubectl exec -it vault-0 -n $VAULT_NAMESPACE -- vault kv get kv/go-app/config
echo ""

# 7. Применение deployment
echo "7️⃣  Применение deployment..."
kubectl apply -f deploy/apps/go-app/deployment.yaml
echo ""

# 8. Ожидание запуска pod
echo "8️⃣  Ожидание запуска pod (60 секунд)..."
kubectl wait --for=condition=Ready pod -l app=argocd-go-example -n $NAMESPACE --timeout=60s || echo "⚠️  Pod не запустился за 60 секунд"
echo ""

# 9. Проверка статуса pod
echo "9️⃣  Статус pod..."
kubectl get pods -n $NAMESPACE -l app=argocd-go-example
echo ""

# 10. Проверка инжекции секретов
echo "🔟 Проверка инжекции секретов..."
POD_NAME=$(kubectl get pod -n $NAMESPACE -l app=argocd-go-example -o jsonpath='{.items[0].metadata.name}')
echo "Pod: $POD_NAME"
echo ""

echo "📁 Файлы в /vault/secrets/:"
kubectl exec -n $NAMESPACE $POD_NAME -- ls -la /vault/secrets/ 2>/dev/null || echo "❌ Директория /vault/secrets/ не найдена"
echo ""

echo "📄 Содержимое config.env:"
kubectl exec -n $NAMESPACE $POD_NAME -- cat /vault/secrets/config.env 2>/dev/null || echo "❌ Файл config.env не найден"
echo ""

echo "🔧 Переменные окружения:"
kubectl exec -n $NAMESPACE $POD_NAME -- env | grep -E "^(DB_|API_)" || echo "❌ Переменные окружения не найдены"
echo ""

# 11. Проверка логов Vault Agent
echo "1️⃣1️⃣ Логи Vault Agent..."
kubectl logs -n $NAMESPACE $POD_NAME -c vault-agent --tail=20 2>/dev/null || echo "❌ Контейнер vault-agent не найден"
echo ""

echo "=== ✅ Тестирование завершено ==="
echo ""
echo "📝 Полезные команды:"
echo "  - Логи приложения: kubectl logs -n $NAMESPACE $POD_NAME"
echo "  - Описание pod: kubectl describe pod -n $NAMESPACE $POD_NAME"
echo "  - Перезапуск pod: kubectl rollout restart deployment/argocd-go-example -n $NAMESPACE"
echo ""
