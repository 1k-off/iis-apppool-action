Param(
    # IIS ApplicationPool available actions
    [Parameter(Mandatory = $true)]
    [ValidateSet('get-state', 'restart', 'start', 'stop')]
    [string]$Action,
    # Application information name. User can set app-pool
    [Parameter(ParameterSetName = "ApplicationPool", HelpMessage = "Application pool name")]
    [ValidateScript({ $_ -ne "" })]
    [string]$AppPoolName
)

function __getState {
    Param (
        [Parameter(Mandatory = $true)]
        [string]$AppPoolName
    )
    $pool = Get-IISAppPool -Name "$AppPoolName"
    $state = $pool.State
    Write-Output "state=$state" >> $ENV:GITHUB_OUTPUT
    Write-Host "IIS application pool $AppPoolName $state"
}

function __restart {
    Param (
        [Parameter(Mandatory = $true)]
        [string]$AppPoolName
    )
    $__state = (Get-IISAppPool -Name "$AppPoolName").State
    if ($__state -eq "Stopped") {
        Write-Host "IIS application pool $AppPoolName is in stopped state now. You can't restart stopped application pool"
        exit
    }
    Restart-WebAppPool -Name "$AppPoolName"
    Write-Host "IIS application pool $AppPoolName restarted."
}

function __start {
    Param (
        [Parameter(Mandatory = $true)]
        [string]$AppPoolName
    )
    Start-WebAppPool -Name "$AppPoolName"
    Write-Host "IIS application pool $AppPoolName started."
}

function __stop {
    Param (
        [Parameter(Mandatory = $true)]
        [string]$AppPoolName
    )
    $__state = (Get-IISAppPool -Name "$AppPoolName").State
    if ($__state -eq "Stopped") {
        Write-Host "IIS application pool $AppPoolName already stopped."
        exit
    }
    $__pid = $true
    $__sleep = 5
    Stop-WebAppPool -Name "$AppPoolName"
    while ($__pid) {
        $__pid =  Get-WmiObject -Class win32_process -Filter "name='w3wp.exe'" | Where-Object { ($_.CommandLine).Split("`"")[1] -eq "$AppPoolName"} | ForEach-Object { $_.ProcessId }
        if ($__sleep -gt 60) {
            Write-Host "Waited $__sleep seconds for app pool $AppPoolName to stop, but it is still running. Trying to kill process."
            Stop-Process $__pid
            if ($__pid) {
                Write-Host "Internal error occured. Process seems running after sigkill."
            }
            Write-Host "IIS application pool $AppPoolName killed."
            break
        }
        if ($__pid) {
            Start-Sleep -s $__sleep
            $__sleep = $__sleep + 5
        }
    }
    Write-Host "IIS application pool $AppPoolName stopped."
}

function __checkAppPoolExists {
    Param (
        [Parameter(Mandatory = $true)]
        [string]$AppPoolName
    )
    $p = Get-IISAppPool -Name "$AppPoolName" -WarningAction:SilentlyContinue
    if ($null -eq "$p") {
        Write-Host "IIS app pool $AppPoolName does not exist"
        exit
    }
}
# DoAction is a main action switcher.
function DoAction {
    Param(
        [Parameter(Mandatory = $true)]
        [string]$Action
    )
    switch ($Action) {
        "get-state" {
            __getState -AppPoolName "$AppPoolName"
         }
        "restart" {
            __restart -AppPoolName "$AppPoolName"
         }
        "start" {
            __start -AppPoolName "$AppPoolName"
         }
        "stop" {
            __stop -AppPoolName "$AppPoolName"
         }
    }
}

$displayName = "Application Pool"
Write-Host "$displayName action running"

__checkAppPoolExists -AppPoolName "$AppPoolName"
DoAction -Action "$Action"
__getState -AppPoolName "$AppPoolName" | Out-Null
