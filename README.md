# IIS Application pool action

Action for self-hosted runners to manipulate iis application pools.

Required: [IISAdministration](https://learn.microsoft.com/en-us/powershell/module/iisadministration/?view=windowsserver2022-ps)

## Inputs
|Parameter|Description|Required|Possible values|
|---|---|---|---|
|`action`|The action to run|true|`get-state`, `restart`, `start`, `stop`|
|`appPoolName`|Name of the target application pool|true (if `siteName` not specified|Any string|
|`siteName`|Name of the target IIS site|true (if `appPoolName` not specified)|Any string|

## Examples

```yaml
...

jobs:
  example:
    runs-on: [self-hosted, deploy]
    steps:
      - name: Start app pool
        id: start_app_pool
        uses: 1k-off/iis-apppool-action@1.0.0
        with:
          action: start
          siteName: "Default Web Site"
      - run: Write-Host "App pool for the Default Web Site ${{ steps.start_app_pool.outputs.state }}" 

...
```

```yaml
...

jobs:
  example:
    runs-on: [self-hosted, deploy]
    steps:
      - name: Start app pool
        id: start_app_pool
        uses: 1k-off/iis-apppool-action@1.0.0
        with:
          action: start
          appPoolName: "Default Web Site"
      - run: Write-Host "App pool for the Default Web Site ${{ steps.start_app_pool.outputs.state }}" 

...
```
