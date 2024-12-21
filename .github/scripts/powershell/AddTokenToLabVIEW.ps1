# Example: .\AddTokenToLabVIEW.ps1 -MinimumSupportedLVVersion "2021" -SupportedBitness "64" -RelativePath "C:\labview-icon-editor"
param(
    [Parameter(Mandatory=$true)]
    [string]$MinimumSupportedLVVersion,
    [Parameter(Mandatory=$true)]
    [string]$SupportedBitness,
    [Parameter(Mandatory=$true)]
    [string]$RelativePath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$DebugPreference = 'Continue'

Write-Debug "AddTokenToLabVIEW.ps1: Starting"
Write-Debug "Parameters:"
Write-Debug "  MinimumSupportedLVVersion: $MinimumSupportedLVVersion"
Write-Debug "  SupportedBitness: $SupportedBitness"
Write-Debug "  RelativePath: $RelativePath"
Write-Debug "PowerShell Version: $($PSVersionTable.PSVersion)"

# Construct the command as a list of arguments to avoid using Invoke-Expression
$command = 'g-cli'
$args = @(
    '--lv-ver', $MinimumSupportedLVVersion,
    '--arch', $SupportedBitness,
    '-v', "$RelativePath\Tooling\deployment\Create_LV_INI_Token.vi",
    '--', 'LabVIEW', 'Localhost.LibraryPaths', $RelativePath
)

Write-Host "Executing the following command:"
Write-Host "$command $($args -join ' ')"

try {
    # Execute the command directly
    & $command $args

    if ($LASTEXITCODE -eq 0) {
        Write-Host "Create localhost.library path from ini file"
    } else {
        Write-Error "Command failed with exit code: $LASTEXITCODE"
        exit 1
    }
} catch {
    Write-Error "An unexpected error occurred while executing g-cli."
    Write-Error "Error Details: $($_.Exception.Message)"
    exit 1
}

Write-Debug "AddTokenToLabVIEW.ps1: Completed Successfully."
