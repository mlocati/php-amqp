param (
    [Parameter(Mandatory=$true)] [string] $Dependency,
    [Parameter(Mandatory=$true)] [string] $Version
)

# Setup a sane environment
$ErrorActionPreference = 'Stop'
$PSDefaultParameterValues['*:ErrorAction'] = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$ConfirmPreference = 'None'
$WarningPreference = 'Continue'
$InformationPreference = 'Continue'

# Strip leading "v" from the value of the Version parameter
if ($Version -match '^v\d') {
    $Version = $Version.Substring(1)
}

# Inspect the current PHP version
$phpInfo = Get-Php
if ([System.Version]$phpInfo.Version -ge [System.Version]"8.0.0") {
    $vcVersionPart += "vs$($phpInfo.VCVersion)"
} else {
    $vcVersionPart += "vc$($phpInfo.VCVersion)"
}

# Prepare the environment
if (-not(Test-Path C:\build-cache)) {
    New-Item -Path C:\build-cache -ItemType Directory | Out-Null
}

# Download the dependency archive
$zipFile = "$Dependency-$Version-$vcVersionPart-$($phpInfo.Architecture).zip"
if(-not(Test-Path -Path "C:\build-cache\$zipFile")) {
    Write-Host "Downloading $zipFile"
    Invoke-WebRequest -Uri "https://windows.php.net/downloads/pecl/deps/$zipFile" -UseBasicParsing -OutFile "C:\build-cache\$zipFile"
}

# Extract the dependency archive do the deps directory
7z.exe x "C:\build-cache\$zipFile" -oC:\build-cache\deps -aoa -bd
if (-not $?) {
    throw "7zip failed with exit code $LastExitCode"
}
