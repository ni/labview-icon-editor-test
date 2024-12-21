Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$DebugPreference = 'Continue'

param(
    [Parameter(Mandatory=$true)]
    [string]$RelativePath
)

# Validate that $RelativePath exists
if (!(Test-Path $RelativePath)) {
    Write-Error "The provided path '$RelativePath' does not exist."
    exit 1
}

try {
    Write-Debug "Removing existing *.lvlibp files from $RelativePath\resource\plugins"
    Get-ChildItem -Path "$RelativePath\resource\plugins" -Filter '*.lvlibp' | Remove-Item -Force

    Write-Debug "Adding token to LabVIEW (32-bit)"
    .\AddTokenToLabVIEW.ps1 -MinimumSupportedLVVersion 2021 -SupportedBitness 32 -RelativePath "$RelativePath"
    
#    Write-Debug "Preparing LabVIEW source (32-bit)"
#    .\Prepare_LabVIEW_source.ps1 -MinimumSupportedLVVersion 2021 -SupportedBitness 32 -RelativePath "$RelativePath" -LabVIEW_Project #"lv_icon_editor" -Build_Spec "Editor Packed Library"
    
#    Write-Debug "Closing LabVIEW (32-bit)"
#    .\Close_LabVIEW.ps1 -MinimumSupportedLVVersion 2021 -SupportedBitness 32

#    Write-Debug "Adding token to LabVIEW (64-bit)"
#    .\AddTokenToLabVIEW.ps1 -MinimumSupportedLVVersion 2021 -SupportedBitness 64 -RelativePath "$RelativePath"
    
#    Write-Debug "Preparing LabVIEW source (64-bit)"
#    .\Prepare_LabVIEW_source.ps1 -MinimumSupportedLVVersion 2021 -SupportedBitness 64 -RelativePath "$RelativePath" -LabVIEW_Project #"lv_icon_editor" -Build_Spec "Editor Packed Library"
    
#    Write-Debug "Closing LabVIEW (64-bit)"
#    .\Close_LabVIEW.ps1 -MinimumSupportedLVVersion 2021 -SupportedBitness 64

    Write-Host "All scripts executed successfully."
} catch {
    Write-Error "An unexpected error occurred during script execution: $($_.Exception.Message)"
    exit 1
}
