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
- **Source:** локальный репозиторий (`deploy/vault/`)
- **Replicas:** 3 (HA режим)
- **Ingress:** `vault.techbit.su`
- **Файл:** `vault.yaml`

### 3. victoriametrics
VictoriaMetrics Operator и VMCluster.
- **Namespace:** `victoriametrics`
- **Source:** локальный репозиторий (`deploy/victoriametrics/`)
- **Компоненты:**
  - vminsert: 2 реплики (запись данных)
  - vmselect: 2 реплики (чтение данных)
  - vmstorage: 1 реплика (хранение данных)
- **Файл:** `victoriametrics.yaml`

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
argocd app sync victoriametrics
```

## Доступ к VictoriaMetrics

- **vminsert (запись):** `vminsert-victoriametrics.victoriametrics.svc:8480`
- **vmselect (чтение):** `vmselect-victoriametrics.victoriametrics.svc:8481`

## Доступ к Vault

- **UI:** `https://vault.techbit.su`
- **API:** `http://vault.vault.svc:8200`
