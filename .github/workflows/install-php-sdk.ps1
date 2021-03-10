param (
    [Parameter(Mandatory=$true)] [string] $Version
)

# Setup a sane environment
$ErrorActionPreference = 'Stop'
$PSDefaultParameterValues['*:ErrorAction'] = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$ConfirmPreference = 'None'
$WarningPreference = 'Continue'
$InformationPreference = 'Continue'

# Inspect the current PHP version
$phpInfo = Get-Php
if ($phpInfo.ThreadSave) {
    $threadSafetyPart = ''
} else {
    $threadSafetyPart = '-nts'
}
if ([System.Version]$phpInfo.Version -ge [System.Version]"8.0.0") {
    $vcVersionPart += "vs$($phpInfo.VCVersion)"
} elseif ([System.Version]$phpInfo.Version -ge [System.Version]"7.4.0") {
    $vcVersionPart += "vc$($phpInfo.VCVersion)"
} else {
    $vcVersionPart += "VC$($phpInfo.VCVersion)"
}

# Prepare the environment
if (-not(Test-Path C:\build-cache)) {
    New-Item -Path C:\build-cache -ItemType Directory | Out-Null
}

# Download the PHP SDK archive
$sdkBaseName = "php-sdk-$Version"
if (-not(Test-Path -Path "C:\build-cache\$sdkBaseName.zip")) {
    Write-Host "Downloading $sdkBaseName.zip"
    Invoke-WebRequest -Uri "https://codeload.github.com/microsoft/php-sdk-binary-tools/zip/$sdkBaseName" -UseBasicParsing -OutFile "C:\build-cache\$sdkBaseName.zip"
}

# Remove previously configured PHP SDK versions
if (Test-Path -Path "C:\build-cache\php-sdk") {
    if (-not(Test-Path -Path "C:\build-cache\php-sdk\$Version")) {
        Remove-Item -Recurse -Force -Path "C:\build-cache\php-sdk"
    }
}

# Extract the PHP SDK archive
if (-not(Test-Path -Path "C:\build-cache\php-sdk")) {
    7z.exe x "C:\build-cache\$sdkBaseName.zip" -oC:\build-cache -aoa -bd
    if (-not $?) {
        throw "7zip failed with exit code $LastExitCode"
    }
    Move-Item -Path "C:\build-cache\php-sdk-binary-tools-php-sdk-$Version" -Destination "C:\build-cache\php-sdk"
    Set-Content -Path "C:\build-cache\php-sdk\$Version" -Value ""
}

# Download the PHP development archive
$devPackFileName = "php-devel-pack-$($phpInfo.FullVersion)$threadSafetyPart-Win32-$vcVersionPart-$($phpInfo.Architecture).zip"
if (-not(Test-Path "C:\build-cache\$devPackFileName")) {
    Write-Host "Downloading $devPackFileName"
    try {
        Invoke-WebRequest -Uri "http://windows.php.net/downloads/releases/archives/$devPackFileName" -UseBasicParsing -OutFile "C:\build-cache\$devPackFileName"
    } catch {
        Invoke-WebRequest -Uri "http://windows.php.net/downloads/releases/$devPackFileName" -UseBasicParsing -OutFile "C:\build-cache\$devPackFileName"
    }
}

# Extract the PHP development archive
$devPackLocalName = "php-$($phpInfo.FullVersion)$threadSafetyPart-devel-$vcVersionPart-$($phpInfo.Architecture)"
if (-not(Test-Path -Path "C:\build-cache\$devPackLocalName")) {
    7z.exe x "C:\build-cache\$devPackFileName" -oC:\build-cache -aoa -bd
    if (-not $?) {
        throw "7zip failed with exit code $LastExitCode"
    }
    if ($threadSafetyPart -ne '') {
        Move-Item -Path "C:\build-cache\php-$($phpInfo.FullVersion)-devel-$vcVersionPart-$($phpInfo.Architecture)" -Destination "C:\build-cache\$devPackLocalName"
    }
}

# Create the directory for the dependencies
if (-not(Test-Path -Path C:\build-cache\deps)) {
    New-Item -Path C:\build-cache\deps -ItemType Directory | Out-Null
}
if (-not(Test-Path -Path C:\build-cache\deps\bin)) {
    New-Item -Path C:\build-cache\deps\bin -ItemType Directory | Out-Null
}

# Add the PHP development directory to the PATH
$Env:Path = "C:\build-cache\$devPackLocalName;C:\build-cache\deps\bin;$($Env:Path)"
