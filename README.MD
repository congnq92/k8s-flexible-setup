# K8s Flexible Setup

Author: Tom Nguyen, Antigravity CLI, Codex

goal: scalable custom k8s can install in 1 - A VPSs

Keep simple with One Cluster first
Flexible manage nodes
 
One Cluster
  ├─ Control plane: 1 or 3 VPSs
  └─ Worker nodes: 1 to 5,000 VPSs
     └─ Pods: up to 150,000 total

## Groups definition

- groups are groups of things that need to be installed (it is developer-defined)
- each group will have install script for pick to install in desire VPS

  - Control-plane group: install all control-plane components together.
  - Worker group: install all worker components; this is where application and Ingress Pods run.
  - NGINX Ingress group: optional add-on, installed on one or more worker-capable VPSs.

 Control-plane group (Control-plane role) (standard term)
 
  ├─ API server
  ├─ etcd
  ├─ scheduler
  └─ controller manager

  Worker group ( Worker role ) (standard term)
  ├─ container runtime
  ├─ kubelet
  ├─ kube-proxy
  └─ runs Ingress and application Pods
  NGINX Ingress group (developer defined)
