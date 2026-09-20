# Deployment planning

The public install script clones or opens the local repository, then starts the app menu. Select `Deployment plan` to answer planning questions. Create and show a final deployment plan before changing any VPS.

```text
Select network mode
        ↓
Enter amount of VPSs
        ↓
Add VPS nodes
        ↓
Select VPS role and installation groups
        ↓
Validate the plan
        ↓
Show final deployment plan
        ↓
Confirm and deploy
```

## Planning input

| Input | Description |
| --- | --- |
| Network mode | Select `vpc` or `wireguard`. |
| Amount of VPSs | Number of VPSs in the Kubernetes cluster. |
| VPS nodes | Name, public IP, and private IP for each VPS. |
| VPS role | Select control-plane role, worker role, or both. |
| Installation groups | Select Control-plane, Worker, and optional NGINX Ingress groups for each VPS. |

## Final deployment plan

Before deployment, show:

| Field | Description |
| --- | --- |
| Kubernetes version | Derived from the active version branch. |
| Network mode | The selected VPC or WireGuard mode. |
| Nodes | Each VPS, its role, and its selected groups. |
| Install order | Control plane first, then worker nodes and optional NGINX Ingress. |
| Verification | The checks that run after installation. |

## Local deployment data

Generate a deployment ID automatically and organize local state by that ID:

```text
state/
└── deployments/
    └── <deployment-id>/
        ├── plan.yaml
        ├── status.yaml
        └── logs/
```

The saved data supports status display, verification, retry, and resuming a deployment. Do not store SSH keys, kubeconfig files, or join tokens in this state.
