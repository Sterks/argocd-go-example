# Kubernetes Cluster Resources Documentation

**Cluster:** k3s v1.31.4+k3s1  
**Nodes:** 6 (node1-node6)  
**Documentation Date:** 2026-03-28

---

## 📋 Namespaces

| Namespace | Status | Description |
|-----------|--------|-------------|
| `argocd-go-example` | Active | Go App Application |
| `cert-manager` | Active | SSL Certificate Management |
| `cnpg-system` | Active | CloudNative PostgreSQL Operator |
| `gitlab` | Active | GitLab (если используется) |
| `grafana` | Active | Grafana (legacy) |
| `longhorn-system` | Active | Longhorn Storage System |
| `metallb-system` | Active | k3s ServiceLB (klipper-lb) |
| `minio-dev` | Active | MinIO Object Storage |
| `monitoring` | Active | Monitoring Stack |
| `ollama` | Active | Ollama AI Models |
| `postgresql` | Active | PostgreSQL Database |
| `pritunl` | Active | Pritunl VPN Server |
| `registry-system` | Active | Docker Registry |
| `traefik-system` | Active | Traefik Ingress Controller |
| `vault` | Active | HashiCorp Vault |
| `victoriametrics` | Active | VictoriaMetrics Monitoring |

---

## 🚀 Applications (Deployments)

### **argocd-go-example**
| Parameter | Value |
|-----------|-------|
| **Namespace** | `argocd-go-example` |
| **Image** | `192.168.0.101:30500/argocd-go-example:latest` |
| **Replicas** | 2/2 |
| **Age** | 9 days |
| **Selector** | `app=argocd-go-example` |

---

### **cert-manager**
| Parameter | Value |
|-----------|-------|
| **Namespace** | `cert-manager` |
| **Image** | `quay.io/jetstack/cert-manager-controller:v1.15.3` |
| **Replicas** | 1/1 |
| **Age** | 13 days |
| **Purpose** | SSL/TLS Certificate Management |

---

### **Pritunl VPN**
| Parameter | Value |
|-----------|-------|
| **Namespace** | `pritunl` |
| **Image** | `docker.io/jippi/pritunl:1.32.4567.52` |
| **Replicas** | 1/1 |
| **Age** | 5 days |
| **Admin Panel** | `https://192.168.0.101:30443/` |
| **VPN Port** | `192.168.0.101:18489/UDP` |
| **Credentials** | `pritunl / 0ulMh61R2eAj` |

---

### **Docker Registry**
| Parameter | Value |
|-----------|-------|
| **Namespace** | `registry-system` |
| **Image** | `registry:2` |
| **Replicas** | 1/1 |
| **Age** | 9 days |
| **Port** | `5000:30500/TCP` |

---

### **Traefik Ingress Controller**
| Parameter | Value |
|-----------|-------|
| **Namespace** | `traefik-system` |
| **Image** | `docker.io/traefik:v2.11.0` |
| **Replicas** | 2/2 |
| **Age** | 21 hours |
| **Ports** | `80:30080/TCP, 443:30444/TCP` |

---

### **VictoriaMetrics Stack**

#### **Operator**
| Parameter | Value |
|-----------|-------|
| **Namespace** | `victoriametrics` |
| **Image** | `victoriametrics/operator:v0.42.0` |
| **Replicas** | 1/1 |

#### **Grafana**
| Parameter | Value |
|-----------|-------|
| **Namespace** | `victoriametrics` |
| **Image** | `docker.io/grafana/grafana:11.3.1` |
| **Replicas** | 1/1 |
| **Access** | `http://192.168.0.101:30080/` (Host: grafana.techbit.su) |

#### **VMAgent**
| Parameter | Value |
|-----------|-------|
| **Namespace** | `victoriametrics` |
| **Image** | `victoriametrics/vmagent:v1.110.0` |
| **Replicas** | 1/1 |

#### **VMAlert**
| Parameter | Value |
|-----------|-------|
| **Namespace** | `victoriametrics` |
| **Image** | `victoriametrics/vmalert:v1.110.0` |
| **Replicas** | 1/1 |

#### **VMSingle**
| Parameter | Value |
|-----------|-------|
| **Namespace** | `victoriametrics` |
| **Image** | `victoriametrics/victoria-metrics:v1.110.0` |
| **Replicas** | 1/1 |
| **Storage** | 20Gi Longhorn |

---

### **Longhorn System**

#### **Components:**
| Component | Replicas | Image |
|-----------|----------|-------|
| `longhorn-manager` | 6/6 | `longhornio/longhorn-manager:v1.7.2` |
| `longhorn-ui` | 2/2 | `longhornio/longhorn-ui:v1.7.2` |
| `csi-attacher` | 3/3 | `longhornio/csi-attacher:v4.7.0` |
| `csi-provisioner` | 3/3 | `longhornio/csi-provisioner:v4.0.1-20241007` |
| `csi-resizer` | 3/3 | `longhornio/csi-resizer:v1.12.0` |
| `csi-snapshotter` | 3/3 | `longhornio/csi-snapshotter:v7.0.2-20241007` |

#### **Access:**
| Service | URL | Port |
|---------|-----|------|
| **Longhorn UI** | `http://192.168.0.101:81/` | 81 |

---

### **Vault**
| Parameter | Value |
|-----------|-------|
| **Namespace** | `vault` |
| **Image** | `hashicorp/vault:1.15.4` |
| **Replicas** | 3/3 (StatefulSet) |
| **Storage** | 10Gi Longhorn (per pod) |
| **Age** | 4 days |

---

## 🗄️ StatefulSets

| Name | Namespace | Replicas | Image | Storage |
|------|-----------|----------|-------|---------|
| `mongodb` | `pritunl` | 1/1 | `mongo:4.4` | 10Gi Longhorn |
| `vault` | `vault` | 3/3 | `hashicorp/vault:1.15.4` | 10Gi Longhorn ×3 |
| `vmalertmanager-...` | `victoriametrics` | 1/1 | `prom/alertmanager:v0.27.0` | - |

---

## 🌐 Services

### **LoadBalancer Services**

| Service | Namespace | External IPs | Ports | Purpose |
|---------|-----------|--------------|-------|---------|
| `pritunl-vpn` | `pritunl` | 192.168.0.101-106,202 | 18489:30218/UDP | VPN Access |
| `longhorn-lb` | `longhorn-system` | 192.168.0.101-106 | 81:31665/TCP | Longhorn UI |
| `grafana-lb` | `victoriametrics` | 192.168.0.101-106 | 80:31663/TCP | Grafana UI |

### **NodePort Services**

| Service | Namespace | NodePort | Target Port | Purpose |
|---------|-----------|----------|-------------|---------|
| `pritunl-direct` | `pritunl` | 30443 | 443 | Pritunl Admin |
| `docker-registry` | `registry-system` | 30500 | 5000 | Docker Registry |
| `traefik` | `traefik-system` | 30080,30444 | 80,443 | Traefik Ingress |

### **ClusterIP Services**

| Service | Namespace | ClusterIP | Ports | Purpose |
|---------|-----------|-----------|-------|---------|
| `mongodb` | `pritunl` | None (Headless) | 27017 | MongoDB |
| `pritunl` | `pritunl` | 10.43.243.102 | 80,443,1194/UDP | Pritunl Internal |
| `argocd-server` | `argocd` | 10.43.120.197 | 80,443 | ArgoCD API |
| `vm-stack-2-grafana` | `victoriametrics` | 10.43.24.199 | 80 | Grafana Internal |

---

## 📡 Ingress Resources

| Name | Namespace | Class | Host | Port | Backend |
|------|-----------|-------|------|------|---------|
| `longhorn-ingress` | `longhorn-system` | - | longhorn.techbit.su | 80 | longhorn-frontend:80 |
| `grafana` | `victoriametrics` | envoy | grafana.techbit.su | 80 | vm-stack-2-grafana:80 |
| `grafana-ingress` | `victoriametrics` | traefik | grafana.techbit.su | 80 | vm-stack-2-grafana:80 |

---

## 💾 PersistentVolumeClaims

| Name | Namespace | Capacity | Access Mode | StorageClass | Status |
|------|-----------|----------|-------------|--------------|--------|
| `data-mongodb-0` | `pritunl` | 10Gi | RWO | longhorn | Bound |
| `pritunl-data` | `pritunl` | 5Gi | RWO | longhorn | Bound |
| `data-vault-0/1/2` | `vault` | 10Gi | RWO | longhorn | Bound |
| `vmsingle-...` | `victoriametrics` | 20Gi | RWO | longhorn | Bound |
| `vmstorage-...` | `victoriametrics` | 10Gi | RWO | longhorn | Bound |
| `registry-pvc` | `registry-system` | 10Gi | RWO | longhorn | Bound |
| `default-pvc` | `default` | 150Gi | RWO | local-path | Bound |
| `data-my-postgres-...` | `postgresql` | 950Gi | RWO | local-storage | Bound |

---

## 🔌 DaemonSets

| Name | Namespace | Purpose | Pods |
|------|-----------|---------|------|
| `svclb-grafana-lb-...` | `kube-system` | Grafana LoadBalancer | 6/6 |
| `svclb-longhorn-lb-...` | `kube-system` | Longhorn LoadBalancer | 6/6 |
| `svclb-pritunl-vpn-...` | `kube-system` | Pritunl VPN LoadBalancer | 6/6 |
| `longhorn-csi-plugin` | `longhorn-system` | CSI Driver | 6/6 |
| `longhorn-manager` | `longhorn-system` | Storage Manager | 6/6 |
| `vm-stack-2-prometheus-...` | `victoriametrics` | Node Exporter | 6/6 |

---

## 🔐 Access Information

### **Admin Panels:**

| Service | URL | Credentials |
|---------|-----|-------------|
| **Pritunl Admin** | https://192.168.0.101:30443/ | pritunl / 0ulMh61R2eAj |
| **Grafana** | http://192.168.0.101:30080/ | (через Host: grafana.techbit.su) |
| **Longhorn** | http://192.168.0.101:81/ | - |
| **Docker Registry** | 192.168.0.101:30500 | - |

### **VPN Access:**
```
Server: 192.168.0.101:18489/UDP
Protocol: OpenVPN
Client: Pritunl Client (https://client.pritunl.com/)
```

---

## 📊 Storage Summary

| StorageClass | Total PVCs | Total Capacity |
|--------------|------------|----------------|
| `longhorn` | 9 | ~85Gi |
| `local-path` | 2 | ~152Gi |
| `local-storage` | 2 | ~1900Gi |

---

## 🔄 ArgoCD Applications

| Application | Namespace | Status | Source Path |
|-------------|-----------|--------|-------------|
| `pritunl` | `argocd` | Synced | deploy/infrastructure/pritunl |
| `argocd-go-example` | `argocd` | Synced | deploy/apps/go-app |
| `grafana` | `argocd` | Synced | deploy/infrastructure/grafana |
| `longhorn` | `argocd` | Synced | deploy/infrastructure/longhorn |
| `vault` | `argocd` | Synced | deploy/apps/vault |
| `vmcluster` | `argocd` | Synced | deploy/apps/victoriametrics |

---

## 📝 Notes

1. **ArgoCD namespace** в статусе `Terminating` - требует очистки
2. **k3s ServiceLB** используется для LoadBalancer вместо MetalLB
3. **Traefik** установлен как дополнительный Ingress Controller
4. **Longhorn** - основная система хранения для stateful приложений

---

## 🔧 Management Commands

### **Get all resources:**
```bash
kubectl get all -A
kubectl get pvc -A
kubectl get ingress -A
```

### **Access Pritunl:**
```bash
# Get password
kubectl exec -n pritunl $(kubectl get pods -n pritunl -l app=pritunl -o jsonpath='{.items[0].metadata.name}') -- \
  bash -c "export MONGODB_URI='mongodb://mongodb:27017/pritunl' && pritunl default-password"
```

### **Access Grafana:**
```bash
kubectl port-forward -n victoriametrics svc/vm-stack-2-grafana 3000:80
# Open http://localhost:3000
```

---

**Last Updated:** 2026-03-28  
**Maintained by:** DevOps Team
