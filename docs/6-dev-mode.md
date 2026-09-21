# Dev Mode

Dev Mode simulates the selected group-script execution without starting any installer script.

## State

The app saves the selected mode locally:

```text
/tmp/k8s-flexible-setup/devmode.txt
```

The file contains either `Dev` or `Prod`. If the file does not exist, the app uses `Prod` mode.

## App behavior

| Mode | After the two confirmations |
| --- | --- |
| Dev | Starts each planned group script, which prints `Dev Mode: will run <script name>` and exits before any setup command runs. |
| Prod | Runs each planned group installer in order. |

Select `2. Switch mode: Dev | Prod` from the app selector to change the saved mode.
