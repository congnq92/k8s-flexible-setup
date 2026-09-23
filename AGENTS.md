# AI Agent Guidelines

## UI

- Use Gum for the terminal UI.
- To print text:
  - Normal text, use `echo`, `printf` depending on purpose
  - Important, highlight info use `uiPrintInfo`
  - Success info use `uiPrintSuccess`
  - Warning info use `uiPrintWarn`
  - Error info use `uiPrintError`
  - Header use `uiPrintHeader`

## Kubernetes version

- Check the current Git branch name for the active Kubernetes version to work with.
- Branch `v1.37.x` means Kubernetes version `v1.37.x`.
