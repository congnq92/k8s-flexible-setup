# Flexible topology

Yes. The same Kubernetes design can run at all three sizes.

| VPSs | Layout                                                                                      | Groups to pick                                                          | Use                                               |
|------|---------------------------------------------------------------------------------------------|-------------------------------------------------------------------------|---------------------------------------------------|
| 1    | Control plane + worker + Ingress + NGINX Pod                                                | Control-plane + Worker + NGINX Ingress on one VPS                       | Development, test, small non-critical app         |
| 3    | Three nodes: control plane + worker roles on every node; Ingress runs on at least two nodes | Control-plane + Worker on every VPS; NGINX Ingress on at least two VPSs | Small production setup; survives one node failure |
| 8    | 2 load balancers + 3 dedicated control-plane nodes + 3 worker nodes                         | Control-plane on three VPSs; Worker + NGINX Ingress on three VPSs       | Professional HA design                            |

## 1 VPS

```text
Internet → NGINX Ingress → Service → NGINX Pod
                 └─ same VPS: Kubernetes control plane + worker
```

For one VPS, no separate load balancer is needed: Internet can reach NGINX Ingress directly through that VPS public IP.

## 3 VPS

```text
Internet → shared public endpoint → Ingress on node 1/2/3
                              └─ each node: control plane + worker
```

For three VPSs, the Kubernetes control plane can be HA, but Internet failover still needs a shared public IP, DNS failover, or a load balancer.

## 8 VPS

```text
Internet → LB-1 / LB-2 → Ingress on 3 worker VPSs
                         └─ 3 separate control-plane VPSs
```

For eight VPSs, the two load-balancer VPSs provide the public HA entry point; this is the full design.
