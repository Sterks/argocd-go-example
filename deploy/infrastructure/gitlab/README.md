# GitLab Deployment Guide

GitLab CE deployment optimized for resource-constrained Kubernetes cluster.

## Resource Requirements

### Minimum Requirements
- **CPU:** 4 cores (we allocate ~3.5 cores)
- **Memory:** 8GB RAM (we allocate ~6GB)
- **Storage:** 50GB+ (we allocate 65GB)

### Your Cluster Capacity
| Node  | CPU (total/used) | Memory (total/used) |
|-------|------------------|---------------------|
| node1 | 2 cores / 12%    | 8GB / 63%           |
| node2 | 2 cores / 5%     | 8GB / 34%           |
| node3 | 2 cores / 4%     | 8GB / 47%           |
| node4 | 2 cores / 3%     | 8GB / 55%           |
| node5 | 2 cores / 5%     | 8GB / 57%           |
| node6 | 2 cores / 32%    | 8GB / 53%           |

**Verdict:** ✅ You have enough resources for GitLab deployment.

## Storage Allocation

| Component   | Size  | StorageClass |
|-------------|-------|--------------|
| PostgreSQL  | 20Gi  | longhorn     |
| Gitaly      | 30Gi  | longhorn     |
| Registry    | 10Gi  | longhorn     |
| Redis       | 5Gi   | longhorn     |
| **Total**   | 65Gi  |              |

## Pre-deployment Checklist

1. **Verify Longhorn is running:**
   ```bash
   kubectl get pods -n longhorn-system
   ```

2. **Verify cert-manager is running:**
   ```bash
   kubectl get pods -n cert-manager
   ```

3. **Verify Traefik is running:**
   ```bash
   kubectl get pods -n traefik
   ```

4. **Add DNS entry (optional):**
   ```bash
   # Add to your DNS or /etc/hosts
   192.168.0.101 gitlab.techbit.su
   ```

## Deployment via ArgoCD

### Option 1: Using ArgoCD UI

1. Open ArgoCD UI: https://argocd.techbit.su
2. Click "New App"
3. Configure:
   - **Name:** gitlab
   - **Project:** default
   - **Repository URL:** https://github.com/derunov/argocd-go-example.git
   - **Path:** deploy/infrastructure/gitlab
   - **Cluster URL:** https://kubernetes.default.svc
   - **Namespace:** gitlab
4. Click "Create"
5. Click "Sync" to deploy

### Option 2: Using kubectl

```bash
# Apply the Application manifest
kubectl apply -f deploy/infrastructure/gitlab/application.yaml

# Or apply all manifests
kubectl apply -k deploy/infrastructure/gitlab/
```

### Option 3: Using ArgoCD CLI

```bash
argocd app create gitlab \
  --repo https://github.com/derunov/argocd-go-example.git \
  --path deploy/infrastructure/gitlab \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace gitlab \
  --auto-prune \
  --self-heal

argocd app sync gitlab
```

## Post-deployment

### 1. Wait for GitLab to be ready

```bash
kubectl get pods -n gitlab -w
```

Wait until all pods show `Running` status (may take 5-10 minutes).

### 2. Get the root password

The initial root password is stored in a secret:

```bash
kubectl get secret gitlab-initial-password -n gitlab -o jsonpath='{.data.password}' | base64 -d
```

**Default password:** `GitLab@Secure2024!`

### 3. Access GitLab

Open in browser: http://gitlab.techbit.su

Login with:
- **Username:** root
- **Password:** (from step 2)

### 4. Change the root password

**IMPORTANT:** Change the default password immediately after first login!

1. Go to User Settings → Password
2. Enter current password
3. Enter new strong password
4. Click "Update password"

### 5. Update the secret with new password

After changing the password in UI, update the Kubernetes secret:

```bash
kubectl create secret generic gitlab-initial-password \
  --from-literal=password='YourNewPassword' \
  -n gitlab \
  --dry-run=client -o yaml | kubectl apply -f -
```

## Monitoring

### Check pod status
```bash
kubectl get pods -n gitlab
```

### Check resource usage
```bash
kubectl top pods -n gitlab
```

### View logs
```bash
# Webservice logs
kubectl logs -n gitlab -l app=webservice -f

# Sidekiq logs
kubectl logs -n gitlab -l app=sidekiq -f

# Gitaly logs
kubectl logs -n gitlab -l app=gitaly -f
```

### Check PVC status
```bash
kubectl get pvc -n gitlab
```

## Troubleshooting

### GitLab pods not starting

1. **Check events:**
   ```bash
   kubectl describe pod -n gitlab <pod-name>
   ```

2. **Check PVC binding:**
   ```bash
   kubectl get pvc -n gitlab
   ```

3. **Check resource quotas:**
   ```bash
   kubectl describe quota -n gitlab
   ```

### Out of memory errors

If you see OOMKilled errors, increase memory limits in `values.yaml`:

```yaml
gitlab:
  webservice:
    resources:
      limits:
        memory: 2Gi  # Increase from 1.5Gi
```

### Database connection errors

Wait for PostgreSQL to be fully ready:

```bash
kubectl get pods -n gitlab -l app=postgresql -w
```

## Backup

### Manual backup

```bash
# Backup PostgreSQL
kubectl exec -n gitlab gitlab-postgresql-0 -- pg_dump -U gitlab gitlabhq_production > gitlab-db-backup.sql

# Backup Gitaly repositories
kubectl exec -n gitlab gitlab-gitaly-0 -- tar -czf /tmp/gitlab-repos.tar.gz /var/opt/gitlab/git-data
```

### Automated backup (recommended)

Set up Velero for cluster-wide backups:

```bash
# Install Velero
helm repo add vmware-tanzu https://vmware-tanzu.github.io/helm-charts
helm install velero vmware-tanzu/velero \
  --namespace velero \
  --create-namespace \
  -f velero-values.yaml
```

## Integration with Harbor

GitLab is configured to use the integrated registry. To push images:

```bash
# Login to GitLab registry
docker login registry.gitlab.techbit.su \
  -u <username> \
  -p <gitlab-token>

# Tag and push image
docker tag myimage:latest registry.gitlab.techbit.su/<group>/<project>/myimage:latest
docker push registry.gitlab.techbit.su/<group>/<project>/myimage:latest
```

## CI/CD with GitLab Runner

Install GitLab Runner separately:

```bash
helm repo add gitlab https://charts.gitlab.io
helm install gitlab-runner gitlab/gitlab-runner \
  -n gitlab-runners \
  --create-namespace \
  -f gitlab-runner-values.yaml
```

## Resource Optimization

If GitLab is using too many resources, you can further optimize:

1. **Reduce Sidekiq concurrency** in `values.yaml`:
   ```yaml
   sidekiq:
     concurrency: 5  # Reduce from 10
   ```

2. **Disable unused features:**
   ```yaml
   gitlab:
     rails:
       gravatar_enabled: false
       mattermost_enabled: false
   ```

3. **Reduce Prometheus retention:**
   ```yaml
   prometheus:
     retention: 6h  # Reduce from default
   ```

## Uninstall

```bash
# Delete ArgoCD application
argocd app delete gitlab

# Or using kubectl
kubectl delete -f deploy/infrastructure/gitlab/application.yaml

# Clean up PVCs (optional - data will be lost!)
kubectl delete pvc -n gitlab --all
```

## Support

- GitLab Documentation: https://docs.gitlab.com
- GitLab Helm Chart: https://artifacthub.io/packages/helm/gitlab/gitlab
- Issues: https://github.com/derunov/argocd-go-example/issues
