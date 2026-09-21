# Network modes

## WireGuard when no VPC is available

WireGuard private mesh is simple for a small number of VPSs. It adds encrypted private connections; it does not replace Kubernetes.

```text
Public Internet
     │
     ├─────────────── public IP ───────────────┐
     ▼                                         ▼
Control-plane VPS                         Worker VPS
public: 203.0.113.10                      public: 203.0.113.20
wg:     10.10.0.10                         wg:     10.10.0.20
     │                                         │
     └──────── encrypted WireGuard tunnel ─────┘
                       │
                       ▼
             Kubernetes private traffic
        API · etcd · kubelet · node-to-node
```

Application traffic stays separate:

```text
Internet → public IP → NGINX Ingress → Service → Pod
```

Use the WireGuard addresses (`10.10.0.x`) only for Kubernetes internal communication.

## Select one network mode

Choose one network mode before installing Kubernetes:

```sh
NETWORK_MODE=vpc
```

or:

```sh
NETWORK_MODE=wireguard
```

Do not use both.

## Installer input

When the Control-plane or Worker group first runs on a VPS, select the network mode and enter the private IP already assigned to that VPS. The group script saves these values locally on that VPS and uses the private IP for the control-plane API server and kubelet node address.

```text
NETWORK_MODE=wireguard
NODE_PRIVATE_IP=10.10.0.12
```

The installer does not configure VPC or WireGuard, and does not store WireGuard keys.
