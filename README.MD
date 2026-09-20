# K8s Flexible Setup

- Author: Tom Nguyen, Antigravity CLI, Codex

## Documentation

- [Plan](docs/1-plan.md)
- [Groups definition](docs/2-groups-definition.md)
- [Flexible topology](docs/3-flexible.md)
- [Mermaid diagrams](docs/4-diagrams.md)
- [Network modes](docs/5-network-modes.md)

## UI

Use Gum.

## Project directory

```text
k8s-flexible-setup/
├── scripts/
│   ├── install.sh       # public bootstrap: clone/check repository, then start app.sh
│   ├── app.sh           # install Gum if needed, then select a group script
│   ├── groups/          # control-plane, worker, and NGINX Ingress installers
│   └── lib/             # shared shell functions
├── config/
├── state/               # local deployment plans, status, and logs; ignored by Git
└── docs/
```

## Install

Linux is the first supported platform.

```sh
curl -fsSL https://raw.githubusercontent.com/congnq92/k8s-flexible-setup/v-1-37-x/scripts/install.sh | bash
```

- `v-1-37-x` is current active branch.
