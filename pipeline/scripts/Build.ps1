<#
.SYNOPSIS
  Build.ps1 - A script to build and test a LabVIEW project on Windows.

.DESCRIPTION
  This script:
  1. Cleans up old .lvlibp files.
  2. Applies VIPC dependencies (32-bit & 64-bit).
  3. Sets development mode.
  4. Runs unit tests (32-bit & 64-bit).
  5. Builds .lvlibp libraries (32-bit & 64-bit).
  6. Closes LabVIEW.
  7. Renames built .lvlibp files (32-bit & 64-bit).
  8. Builds a VI Package.
  9. Reverts development mode.

.PARAMETER RelativePath
  The root folder of the project (where resource/plugins, lvproj, etc. live).

.PARAMETER AbsolutePathScripts
  The full path to the folder containing these pipeline scripts.

.EXAMPLE
  .\Build.ps1 -RelativePath "C:\labview-icon-editor" -AbsolutePathScripts "C:\labview-icon-editor\pipeline\scripts"
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$RelativePath,

    [Parameter(Mandatory = $true)]
    [string]$AbsolutePathScripts
)

#----------------------------------------------------------------------------------
# Helper function: Asserts a given file or folder path exists; exits if not found.
#----------------------------------------------------------------------------------
function Assert-PathExists {
    param(
        [string]$Path,
        [string]$Description
    )
    if (-Not (Test-Path -Path $Path)) {
        Write-Host "The $Description does not exist: $Path" -ForegroundColor Red
        exit 1
    }
}

#----------------------------------------------------------------------------------
# Helper function: Executes a PowerShell script with arguments.
# Exits this script if the called script returns a non-zero exit code or throws.
#----------------------------------------------------------------------------------
function Execute-Script {
    param(
        [string]$ScriptPath,
        [string]$Arguments
    )

    Write-Host "Executing: $ScriptPath $Arguments" -ForegroundColor Cyan

    try {
        # Build a command string which includes the script path & arguments
        $command = "& `"$ScriptPath`" $Arguments"

        # Invoke the PowerShell command
        Invoke-Expression $command

        if ($LASTEXITCODE -ne 0) {
            Write-Host "Error occurred while executing: $ScriptPath with arguments: $Arguments. Exit code: $LASTEXITCODE" -ForegroundColor Red
            exit $LASTEXITCODE
        }
    }
    catch {
        Write-Host "Error occurred while executing: $ScriptPath with arguments: $Arguments. Exiting." -ForegroundColor Red
        exit 1
    }
}

#----------------------------------------------------------------------------------
# Main Script Execution
#----------------------------------------------------------------------------------
try {
    # 1) Normalize the incoming paths to full Windows paths with backslashes.
    $RelativePath        = (Resolve-Path $RelativePath).Path
    $AbsolutePathScripts = (Resolve-Path $AbsolutePathScripts).Path

    # 2) Validate required directories
    Assert-PathExists $RelativePath "RelativePath"
    Assert-PathExists (Join-Path $RelativePath 'resource\plugins') "Plugins folder"
    Assert-PathExists $AbsolutePathScripts "Scripts folder"

    # 3) Clean up .lvlibp files in the plugins folder
    Write-Host "Cleaning up old .lvlibp files in plugins folder..." -ForegroundColor Yellow
    $pluginsFolder = Join-Path $RelativePath 'resource\plugins'
    $pluginFiles = Get-ChildItem -Path $pluginsFolder -Filter '*.lvlibp' -ErrorAction SilentlyContinue
    if ($pluginFiles) {
        $pluginFiles | Remove-Item -Force
        Write-Host "Deleted .lvlibp files from plugins folder." -ForegroundColor Green
    }
    else {
        Write-Host "No .lvlibp files found to delete." -ForegroundColor Cyan
    }

    # 4) Apply dependencies for 32-bit LabVIEW 2021
    $applyvipcScript = Join-Path $AbsolutePathScripts 'Applyvipc.ps1'
    Execute-Script $applyvipcScript `
        '-MinimumSupportedLVVersion 2021 -SupportedBitness 32 ' +
        "-RelativePath `"$RelativePath`" " +
        '-VIPCPath `"Tooling\deployment\dependencies.vipc`" ' +
        '-VIP_LVVersion 2021'

    # 5) Apply dependencies for 64-bit LabVIEW 2021
    Execute-Script $applyvipcScript `
        '-MinimumSupportedLVVersion 2021 -SupportedBitness 64 ' +
        "-RelativePath `"$RelativePath`" " +
        '-VIPCPath `"Tooling\deployment\dependencies.vipc`" ' +
        '-VIP_LVVersion 2021'

    # 6) Set development mode
    $setDevModeScript = Join-Path $AbsolutePathScripts 'Set_Development_Mode.ps1'
    Execute-Script $setDevModeScript "-RelativePath `"$RelativePath`""

    # 7) Run Unit Tests (32-bit)
    $runTestsScript = Join-Path $AbsolutePathScripts 'RunUnitTests.ps1'
    Execute-Script $runTestsScript "-MinimumSupportedLVVersion 2021 -SupportedBitness 32 -RelativePath `"$RelativePath`""

    # 8) Build LV Library (32-bit)
    $buildLvlibpScript = Join-Path $AbsolutePathScripts 'Build_lvlibp.ps1'
    Execute-Script $buildLvlibpScript "-MinimumSupportedLVVersion 2021 -SupportedBitness 32 -RelativePath `"$RelativePath`""

    # 9) Close LabVIEW (32-bit)
    $closeLabViewScript = Join-Path $AbsolutePathScripts 'Close_LabVIEW.ps1'
    Execute-Script $closeLabViewScript "-MinimumSupportedLVVersion 2021 -SupportedBitness 32"

    # 10) Rename the file after build (32-bit)
    $renameFileScript = Join-Path $AbsolutePathScripts 'Rename-File.ps1'
    Execute-Script $renameFileScript `
        "-CurrentFilename `"$RelativePath\resource\plugins\lv_icon.lvlibp`" -NewFilename 'lv_icon_x86.lvlibp'"

    # 11) Run Unit Tests (64-bit)
    Execute-Script $runTestsScript "-MinimumSupportedLVVersion 2021 -SupportedBitness 64 -RelativePath `"$RelativePath`""

    # 12) Build LV Library (64-bit)
    Execute-Script $buildLvlibpScript "-MinimumSupportedLVVersion 2021 -SupportedBitness 64 -RelativePath `"$RelativePath`""

    # 13) Rename the file after build (64-bit)
    Execute-Script $renameFileScript `
        "-CurrentFilename `"$RelativePath\resource\plugins\lv_icon.lvlibp`" -NewFilename 'lv_icon_x64.lvlibp'"

    # 14) Build VI Package
    $buildVipScript = Join-Path $AbsolutePathScripts 'build_vip.ps1'
    Execute-Script $buildVipScript `
        "-SupportedBitness 64 -RelativePath `"$RelativePath`" -VIPBPath `"Tooling\deployment\NI Icon editor.vipb`" -VIP_LVVersion 2021 -MinimumSupportedLVVersion 2021"

    # 15) Close LabVIEW (64-bit)
    Execute-Script $closeLabViewScript "-MinimumSupportedLVVersion 2021 -SupportedBitness 64"

    # 16) Revert development mode
    $revertDevModeScript = Join-Path $AbsolutePathScripts 'RevertDevelopmentMode.ps1'
    Execute-Script $revertDevModeScript "-RelativePath `"$RelativePath`""

    Write-Host "All scripts executed successfully!" -ForegroundColor Green
}
catch {
    Write-Host "An unexpected error occurred during script execution: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
