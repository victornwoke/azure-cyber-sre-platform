param(
    [string]$ResourceGroupName = "rg-cyber-sre-dev"
)

$ErrorActionPreference = "Stop"

$Checks = @()

function Add-Check {
    param(
        [string]$Name,
        [string]$Status,
        [string]$Message
    )

    $script:Checks += [PSCustomObject]@{
        Check   = $Name
        Status  = $Status
        Message = $Message
    }
}

try {
    $Context = Get-AzContext

    if ($null -eq $Context) {
        throw "No active Azure session"
    }

    Add-Check `
        -Name "Azure Authentication" `
        -Status "PASS" `
        -Message "Connected to Azure"
}
catch {
    Add-Check `
        -Name "Azure Authentication" `
        -Status "FAIL" `
        -Message $_.Exception.Message
}

try {
    $ResourceGroup = Get-AzResourceGroup `
        -Name $ResourceGroupName

    Add-Check `
        -Name "Resource Group" `
        -Status "PASS" `
        -Message $ResourceGroup.ResourceGroupName
}
catch {
    Add-Check `
        -Name "Resource Group" `
        -Status "FAIL" `
        -Message $_.Exception.Message
}

try {
    $DataFactory = Get-AzDataFactoryV2 `
        -ResourceGroupName $ResourceGroupName |
    Select-Object -First 1

    if ($null -eq $DataFactory) {
        throw "Data Factory not found"
    }

    Add-Check `
        -Name "Data Factory" `
        -Status "PASS" `
        -Message $DataFactory.DataFactoryName
}
catch {
    Add-Check `
        -Name "Data Factory" `
        -Status "FAIL" `
        -Message $_.Exception.Message
}

try {
    $Workspace = Get-AzOperationalInsightsWorkspace `
        -ResourceGroupName $ResourceGroupName |
    Select-Object -First 1

    if ($null -eq $Workspace) {
        throw "Log Analytics workspace not found"
    }

    Add-Check `
        -Name "Log Analytics" `
        -Status "PASS" `
        -Message $Workspace.Name
}
catch {
    Add-Check `
        -Name "Log Analytics" `
        -Status "FAIL" `
        -Message $_.Exception.Message
}

$Checks | Format-Table -AutoSize

if ($Checks.Status -contains "FAIL") {
    Write-Host "Platform Status: DEGRADED"
    exit 1
}

Write-Host "Platform Status: HEALTHY"
exit 0