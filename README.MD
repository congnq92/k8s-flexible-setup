# K8s Flexible Setup

- Author: Tom Nguyen, Antigravity CLI, Codex

## Documentation

- [Plan](docs/1-plan.md)
- [Groups definition](docs/2-groups-definition.md)
- [Flexible topology](docs/3-flexible.md)
- [Mermaid diagrams](docs/4-diagrams.md)
- [Network modes](docs/5-network-modes.md)
- [Dev Mode](docs/6-dev-mode.md)
- [Storage](docs/7-storage.md)
- [Pin a database Pod](docs/8-pin-pod.md)

## UI

Use [Gum](https://github.com/charmbracelet/gum)

## Project directory

```text
k8s-flexible-setup/
├── scripts/
│   ├── install.sh       # public bootstrap: clone/check repository and print the app command
│   ├── app/             # main.sh, UI, and services
│   ├── groups/          # control-plane, worker, and NGINX Ingress installers
│   └── ...
└── docs/
```

## Install

Linux is the first supported platform.

```sh
curl -fsSL https://raw.githubusercontent.com/congnq92/k8s-flexible-setup/v1.37.x/scripts/install.sh | bash
```

The bootstrap script only installs the repository. Then start the app in the terminal:

```sh
bash ~/.local/share/k8s-flexible-setup/scripts/app/main.sh
```

- `v1.37.x` is the current active branch.

## Development
- Hot reloading
```shell
sh scripts/modules/dev/hot-reloading.sh
```
