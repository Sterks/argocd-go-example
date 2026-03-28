# LoadBalancer Configuration Documentation

**Cluster:** k3s v1.31.4+k3s1  
**LoadBalancer Type:** k3s ServiceLB (klipper-lb)  
**Date:** 2026-03-28

---

## 📋 Overview

В кластере используется **k3s ServiceLB** (klipper-lb) для предоставления LoadBalancer сервисов.

**Почему не MetalLB:**
- MetalLB установлен, но не настроен (пустой IPAddressPool)
- k3s ServiceLB работает "из коробки" и проще в управлении
- ServiceLB использует DaemonSet на каждой ноде

---

## 🔄 Как работает k3s ServiceLB

### **Архитектура:**

```
                    ┌─────────────────────────────────────┐
                    │         External Traffic            │
                    └──────────────┬──────────────────────┘
                                   │
                    ┌──────────────▼──────────────────────┐
                    │     LoadBalancer External IPs       │
                    │  (192.168.0.101-106 на каждой ноде) │
                    └──────────────┬──────────────────────┘
                                   │
        ┌──────────────────────────┼──────────────────────────┐
        │                          │                          │
┌───────▼────────┐        ┌───────▼────────┐        ┌───────▼────────┐
│   Node 1       │        │   Node 2       │        │   Node 6       │
│ 192.168.0.101  │        │ 192.168.0.102  │        │ 192.168.0.106  │
│ ┌────────────┐ │        │ ┌────────────┐ │        │ ┌────────────┐ │
│ │klipper-lb  │ │        │ │klipper-lb  │ │        │ │klipper-lb  │ │
│ │  DaemonSet │ │        │ │  DaemonSet │ │        │ │  DaemonSet │ │
│ └─────┬──────┘ │        │ └─────┬──────┘ │        │ └─────┬──────┘ │
│       │        │        │       │        │        │       │        │
│       ▼        │        │       ▼        │        │       ▼        │
│  ┌────────┐   │        │  ┌────────┐   │        │  ┌────────┐   │
│  │ Service│   │        │  │ Service│   │        │  │ Service│   │
│  │  Pod   │   │        │  │  Pod   │   │        │  │  Pod   │   │
│  └────────┘   │        │  └────────┘   │        │  └────────┘   │
└───────────────┘        └───────────────┘        └───────────────┘
```

### **Принцип работы:**

1. **При создании Service типа LoadBalancer:**
   - k3s автоматически создаёт DaemonSet `svclb-<service-name>-<uid>`
   - DaemonSet запускает pod на каждой ноде кластера

2. **klipper-lb DaemonSet:**
   - Использует образ `rancher/klipper-lb:v0.4.9`
   - Запускает простой TCP/UDP балансировщик на каждой ноде
   - Открывает NodePort и перенаправляет трафик на ClusterIP сервиса

3. **External IPs:**
   - Каждый pod klipper-lb получает External IP из Internal IP ноды
   - Все ноды отвечают на один и тот же External IP сервиса

---

## 📊 Текущие LoadBalancer Сервисы

### **1. Pritunl VPN**

```yaml
Name: pritunl-vpn
Namespace: pritunl
Type: LoadBalancer
ClusterIP: 10.43.252.71
External IPs: 192.168.0.101,192.168.0.102,192.168.0.103,
              192.168.0.104,192.168.0.105,192.168.0.106,192.168.0.202
Port: 18489/UDP
NodePort: 30218/UDP
TargetPort: 1194/UDP
```

**DaemonSet:**
```yaml
Name: svclb-pritunl-vpn-be535de0
Image: rancher/klipper-lb:v0.4.9
Pods: 6/6 (на всех нодах)
Protocol: UDP
Port: 18489
```

**Доступ:**
```bash
# С любой ноды кластера
192.168.0.101:18489/UDP
192.168.0.102:18489/UDP
# и т.д.
```

---

### **2. Longhorn UI**

```yaml
Name: longhorn-lb
Namespace: longhorn-system
Type: LoadBalancer
ClusterIP: 10.43.67.122
External IPs: 192.168.0.101,192.168.0.102,192.168.0.103,
              192.168.0.104,192.168.0.105,192.168.0.106
Port: 81/TCP
NodePort: 31665/TCP
TargetPort: 8000/TCP
```

**DaemonSet:**
```yaml
Name: svclb-longhorn-lb-21295983
Image: rancher/klipper-lb:v0.4.9
Pods: 6/6
Protocol: TCP
Port: 81
```

**Доступ:**
```bash
# Web UI
http://192.168.0.101:81/
http://192.168.0.102:81/
# и т.д.
```

---

### **3. Grafana**

```yaml
Name: grafana-lb
Namespace: victoriametrics
Type: LoadBalancer
ClusterIP: 10.43.81.204
External IPs: 192.168.0.101,192.168.0.102,192.168.0.103,
              192.168.0.104,192.168.0.105,192.168.0.106
Port: 80/TCP
NodePort: 31663/TCP
TargetPort: 3000/TCP
```

**DaemonSet:**
```yaml
Name: svclb-grafana-lb-59e761a6
Image: rancher/klipper-lb:v0.4.9
Pods: 6/6
Protocol: TCP
Port: 80
```

**Доступ:**
```bash
# С Host заголовком
curl -H "Host: grafana.techbit.su" http://192.168.0.101:80/

# Или через Traefik
http://192.168.0.101:30080/ (Host: grafana.techbit.su)
```

---

## 🔧 Управление LoadBalancer

### **Просмотр всех LB сервисов:**
```bash
kubectl get svc -A -o wide | grep LoadBalancer
```

### **Просмотр DaemonSet'ов:**
```bash
kubectl get daemonset -n kube-system | grep svclb
```

### **Детали конкретного DaemonSet:**
```bash
kubectl get daemonset -n kube-system svclb-grafana-lb-59e761a6 -o yaml
```

### **Логи klipper-lb pod:**
```bash
# Найти pod
kubectl get pods -n kube-system -l app=svclb-grafana-lb-59e761a6

# Посмотреть логи
kubectl logs -n kube-system svclb-grafana-lb-59e761a6-xxxxx
```

---

## ⚙️ Конфигурация k3s ServiceLB

### **Отключить ServiceLB (если нужен MetalLB):**

В `/etc/rancher/k3s/config.yaml` на всех нодах:
```yaml
disable:
- servicelb
```

Перезапуск:
```bash
sudo systemctl restart k3s
```

### **Изменить диапазон NodePort:**

В `/etc/rancher/k3s/config.yaml`:
```yaml
kube-apiserver-arg:
  - service-node-port-range=30000-32767
```

---

## 🆚 Сравнение: k3s ServiceLB vs MetalLB

| Характеристика | k3s ServiceLB | MetalLB |
|----------------|---------------|---------|
| **Сложность** | Низкая (из коробки) | Средняя (требует настройки) |
| **Режим работы** | DaemonSet на каждой ноде | Speaker + Controller |
| **IP адреса** | Internal IP нод | Выделенный пул IP |
| **L2 Announce** | Нет (работает на каждой ноде) | Да (ARP на один IP) |
| **Failover** | Все ноды активны | Один лидер + backup |
| **Поддержка** | Только TCP/UDP | TCP/UDP + BGP |
| **Использование** | Простые сценарии | Production с BGP |

---

## 🎯 Рекомендации

### **Когда использовать k3s ServiceLB:**
- ✅ Простые deployment'ы
- ✅ Development/Staging окружения
- ✅ Когда все ноды доступны извне
- ✅ Не нужен BGP

### **Когда использовать MetalLB:**
- ✅ Production окружения
- ✅ Нужен единый VIP адрес
- ✅ Требуется BGP анонсирование
- ✅ Сложные сети с несколькими подсетями

---

## 🔍 Troubleshooting

### **LoadBalancer в статусе Pending:**
```bash
# Проверить что servicelb включён
kubectl get daemonset -n kube-system | grep svclb

# Проверить логи
kubectl logs -n kube-system -l app=svclb-<service-name>
```

### **Трафик не проходит:**
```bash
# Проверить firewall на нодах
sudo iptables -L -n | grep <port>

# Проверить что pod слушает порт
kubectl get endpoints <service-name> -n <namespace>
```

### **Удалить LoadBalancer сервис:**
```bash
kubectl delete svc <service-name> -n <namespace>
# DaemonSet удалится автоматически
```

---

## 📝 Примеры

### **Создать LoadBalancer сервис:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-app-lb
  namespace: default
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 8080
    protocol: TCP
  selector:
    app: my-app
```

**Применить:**
```bash
kubectl apply -f service.yaml
```

**Проверить:**
```bash
kubectl get svc my-app-lb -o wide
# External IP будет Internal IP нод
```

---

**Last Updated:** 2026-03-28  
**Author:** DevOps Team
