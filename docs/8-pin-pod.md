# Pin a database Pod

For local PVC storage, pin the database Pod to the VPS where its volume is created.

## 1. Label the selected VPS node

```sh
kubectl get nodes
kubectl label node <vps-4-node-name> workload=database
```

## 2. Select that node in the database StatefulSet

```yaml
spec:
  template:
    spec:
      nodeSelector:
        workload: database
```

## 3. Use delayed local-volume binding

Set the local StorageClass to `WaitForFirstConsumer`. Kubernetes schedules the database Pod on the labeled node before creating its local PVC volume.

If that VPS is unavailable, the database Pod remains Pending rather than starting on another VPS without its data.
