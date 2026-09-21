# Storage

## Local Storage

The simplest storage solution is the Local Storage group. Run it once from the first control-plane VPS; it installs local-path-provisioner and makes `local-path` the default StorageClass.

For a database, use a PersistentVolumeClaim (PVC). The local provisioner creates the volume on the selected VPS disk, so database data remains after a Pod, Kubernetes, or VPS restart.

Label every VPS that may run a database Pod, then pin the database Pod to one selected VPS. The local provisioner creates the PVC volume on that VPS disk. See [Pin a database Pod](8-pin-pod.md).

This is not high-availability storage: if the selected VPS or its disk fails, the database is unavailable. Keep backups outside that VPS.

## Cloud Storage

TODO: add cloud storage setup later.
