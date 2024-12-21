#.\Set_Development_Mode.ps1 -RelativePath "C:\labview-icon-editor"
param(
    [Parameter(Mandatory=$true)]
    [string]$RelativePath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$DebugPreference = 'Continue'

# Helper function to execute scripts and stop on error
function Execute-Script {
    param(
        [Parameter(Mandatory=$true)]
        [scriptblock]$CommandBlock
    )

    Write-Host "Executing: $($CommandBlock.ToString())"
    try {
        & $CommandBlock
    }
    catch {
        Write-Error "Error occurred while executing: $($CommandBlock.ToString()). Exiting."
        exit 1
    }
}

try {
    # Remove existing .lvlibp files
    Execute-Script {
        Get-ChildItem -Path "$RelativePath\resource\plugins" -Filter '*.lvlibp' | Remove-Item -Force
    }

    # Add token to LabVIEW (32-bit)
    Execute-Script {
        .\AddTokenToLabVIEW.ps1 -MinimumSupportedLVVersion 2021 -SupportedBitness 32 -RelativePath "$RelativePath"
    }

    # Prepare LabVIEW source (32-bit)
    Execute-Script {
        .\Prepare_LabVIEW_source.ps1 -MinimumSupportedLVVersion 2021 -SupportedBitness 32 -RelativePath "$RelativePath" -LabVIEW_Project 'lv_icon_editor' -Build_Spec 'Editor Packed Library'
    }

    # Close LabVIEW (32-bit)
    Execute-Script {
        .\Close_LabVIEW.ps1 -MinimumSupportedLVVersion 2021 -SupportedBitness 32
    }

    # Add token to LabVIEW (64-bit)
    Execute-Script {
        .\AddTokenToLabVIEW.ps1 -MinimumSupportedLVVersion 2021 -SupportedBitness 64 -RelativePath "$RelativePath"
    }

    # Prepare LabVIEW source (64-bit)
    Execute-Script {
        .\Prepare_LabVIEW_source.ps1 -MinimumSupportedLVVersion 2021 -SupportedBitness 64 -RelativePath "$RelativePath" -LabVIEW_Project 'lv_icon_editor' -Build_Spec 'Editor Packed Library'
    }

    # Close LabVIEW (64-bit)
    Execute-Script {
        .\Close_LabVIEW.ps1 -MinimumSupportedLVVersion 2021 -SupportedBitness 64
    }

} catch {
    Write-Error "An unexpected error occurred during script execution: $($_.Exception.Message)"
    exit 1
}

Write-Host "All scripts executed successfully."
