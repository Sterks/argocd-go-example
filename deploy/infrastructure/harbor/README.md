# Harbor (Docker Registry)

**Namespace:** harbor
**Date:** 2026-03-28

---

## 📊 Overview

Simple Docker Registry deployed as an alternative to Harbor full stack.

| Component | Image | Port |
|-----------|-------|------|
| **Registry** | `registry:2` | 5000 |

---

## 🔌 Access Points

### **Via Traefik Ingress:**
| Service | URL | Description |
|---------|-----|-------------|
| **Registry API** | http://harbor.techbit.su | Docker registry API |
| **Registry UI** | http://ui.harbor.techbit.su | Web UI |

### **Via NodePort:**
| Service | URL | Description |
|---------|-----|-------------|
| **Registry API** | http://192.168.0.101:30080 (Host: harbor.techbit.su) | Docker registry API |
| **Registry UI** | http://192.168.0.101:30080 (Host: ui.harbor.techbit.su) | Web UI |

### **DNS Configuration:**
✅ **DNS is already configured!** No need to modify `/etc/hosts`.

Domains resolve to: `192.168.0.101`

---

## 🚀 Usage

### **Web UI:**
Open in browser: **http://ui.harbor.techbit.su:30080/**

Features:
- Browse repositories and tags
- View image digests
- Delete images
- Copy docker pull commands

### **Docker Login:**
```bash
# Configure Docker for HTTP registry
# Add to /etc/docker/daemon.json:
# {
#   "insecure-registries": ["harbor.techbit.su:30080"]
# }

docker login harbor.techbit.su:30080
# Username: (any)
# Password: (any)
```

### **Push Image:**
```bash
docker tag myimage:latest harbor.techbit.su:30080/myimage:latest
docker push harbor.techbit.su:30080/myimage:latest
```

### **Pull Image:**
```bash
docker pull harbor.techbit.su:30080/myimage:latest
```

### **List Repositories (API):**
```bash
curl http://harbor.techbit.su:30080/v2/_catalog
```

### **List Tags (API):**
```bash
curl http://harbor.techbit.su:30080/v2/<repository>/tags/list
```

---

## 📁 Files

```
deploy/infrastructure/harbor/
├── registry-simple.yaml    # Main deployment
└── kustomization.yaml      # Kustomize config
```

---

## 🔧 Configuration

### **Storage:**
- **Type:** Longhorn PVC
- **Size:** 10Gi
- **Class:** longhorn

### **Resources:**
```yaml
requests:
  cpu: 100m
  memory: 256Mi
limits:
  cpu: 500m
  memory: 512Mi
```

---

## 🩹 Troubleshooting

### **Check Status:**
```bash
kubectl get pods -n harbor
kubectl get ingress -n harbor
kubectl get pvc -n harbor
```

### **View Logs:**
```bash
kubectl logs -n harbor deployment/registry
```

### **Test Access:**
```bash
# HTTP (DNS configured - no /etc/hosts needed)
curl http://harbor.techbit.su:30080/v2/_catalog

# List tags
curl http://harbor.techbit.su:30080/v2/<repository>/tags/list
```

---

## 🔐 Security Notes

- Currently configured as **public registry** (no authentication)
- For production, add authentication:
  - Basic auth with htpasswd
  - Token-based auth
  - TLS certificates from Let's Encrypt

---

**Last Updated:** 2026-03-29
**Status:** ✅ Working - DNS configured, no /etc/hosts required
**Maintained by:** DevOps Team
