## Groups definition

- Groups are groups of things that need to be installed (it is developer-defined)
- Each group will have installing script for pick to install in desire VPS

| Group               | Role          | Term                   | Installed components / purpose                                                  |
|---------------------|---------------|------------------------|---------------------------------------------------------------------------------|
| Control-plane group | Control-plane | standard term          | API server<br>etcd<br>scheduler<br>controller manager                           |
| Worker group        | Worker        | standard term          | container runtime<br>kubelet<br>kube-proxy<br>Runs Ingress and application Pods |
| NGINX Ingress group | -             | developer-defined term | Optional add-on on worker-capable VPSs                                          |
