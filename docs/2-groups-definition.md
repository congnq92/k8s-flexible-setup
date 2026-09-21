## Groups definition

- Groups are groups of things that need to be installed (it is developer-defined)
- Each group will have installing script for pick to install in desire VPS

| No | Group               | Role          | Term                   | Installed components / purpose                                                  |
|----|---------------------|---------------|------------------------|---------------------------------------------------------------------------------|
| #1 | Control-plane group | Control-plane | standard term          | API server<br>etcd<br>scheduler<br>controller manager                           |
| #2 | Worker group        | Worker        | standard term          | container runtime<br>kubelet<br>kube-proxy<br>Runs Ingress and application Pods |
| #3 | CNI group           | -             | developer-defined term | Required for Pod-to-Pod communication                                           |
| #4 | NGINX Ingress group | -             | developer-defined term | Optional add-on on worker-capable VPSs                                          |
| #5 | Local Storage group | -             | developer-defined term | Installs local-path-provisioner for database PVCs                               |
| #6 | Metrics Server group | -            | developer-defined term | Provides `kubectl top` metrics and enables HPA                                  |
| #7 | Admin Tools group   | -             | developer-defined term | Installs Helm on the administrator VPS                                          |
