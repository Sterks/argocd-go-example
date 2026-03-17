# ArgoCD Applications

В этой директории находятся манифесты ArgoCD Applications для управления приложениями в кластере Kubernetes.

## Приложения

### 1. argocd-go-example
Основное приложение Go примера.
- **Namespace:** `argocd-go-example`
- **Source:** локальный репозиторий
- **Sync Policy:** автоматическая

### 2. vault
HashiCorp Vault в режиме HA с Raft storage backend.
- **Namespace:** `vault`
- **Chart:** `vault` из репозитория HashiCorp
- **Version:** 0.32.0 (Vault 1.21.2)
- **Replicas:** 3 (HA режим)
- **Ingress:** `vault.techbit.su`

> **Примечание:** Если ArgoCD не может синхронизировать Vault из-за недоступности Helm репозитория HashiCorp (403 Forbidden), Vault можно установить вручную:
> ```bash
> helm repo add hashicorp https://helm.releases.hashicorp.com
> helm install vault hashicorp/vault -f deploy/vault/values.yaml -n vault --create-namespace
> ```

### 3. victoria-metrics
VictoriaMetrics Operator для управления CRD.
- **Namespace:** `victoriametrics`
- **Chart:** `victoria-metrics-operator` из репозитория VictoriaMetrics
- **Version:** 0.29.0

### 4. victoria-metrics-cluster
Кластер VictoriaMetrics (VMCluster).
- **Namespace:** `victoriametrics`
- **Source:** локальный репозиторий (`deploy/victoriametrics/`)
- **Компоненты:**
  - vminsert: 2 реплики (запись данных)
  - vmselect: 2 реплики (чтение данных)
  - vmstorage: 1 реплика (хранение данных)

## Быстрый старт

### Установка ArgoCD Applications

```bash
kubectl apply -f deploy/argocd/
```

### Проверка статуса

```bash
kubectl get applications -n argocd
```

### Принудительная синхронизация

```bash
argocd app sync vault
argocd app sync victoria-metrics
argocd app sync victoria-metrics-cluster
```

## Доступ к VictoriaMetrics

- **vminsert (запись):** `vminsert-victoriametrics.victoriametrics.svc:8480`
- **vmselect (чтение):** `vmselect-victoriametrics.victoriametrics.svc:8481`

## Доступ к Vault

- **UI:** `https://vault.techbit.su`
- **API:** `http://vault.vault.svc:8200`
