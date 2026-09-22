# Plan

- Build a scalable custom k8s scripts can install in 1 - A VPSs
- Keep simple with One Cluster first
- Flexible installing: pick groups and install them depending on the amount of VPSs.
- Flexible manage nodes.
- Example:

```text
One Cluster
  ├─ Control plane: 1 or 3 VPSs
  └─ Worker nodes: 1 to 5,000 VPSs
     └─ Pods: up to 150,000 total
```

## App module

```text
scripts/app/
├── main.sh              # application launcher
├── ui.sh                # Gum display, input, and navigation
└── services/
    ├── group-service.sh # group script planning and execution
    └── admin-service.sh # admin script execution

scripts/lib/lib-init.sh                # shared runtime modules
scripts/modules/dev/dev.module.sh      # development-only modules
scripts/config/config.sh               # application configuration
```
