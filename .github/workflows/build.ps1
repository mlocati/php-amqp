# Setup a sane environment
$ErrorActionPreference = 'Stop'
$PSDefaultParameterValues['*:ErrorAction'] = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$ConfirmPreference = 'None'
$WarningPreference = 'Continue'
$InformationPreference = 'Continue'

$phpInfo = Get-Php

if ([System.Version]$phpInfo.Version -ge [System.Version]"8.0.0") {
    $vcVersionPart += "vs$($phpInfo.VCVersion)"
} else {
    $vcVersionPartexit += "vc$($phpInfo.VCVersion)"
}

Set-Content -Path task.bat -Encoding ASCII -Value @"
@echo off

echo ### Check for dependency updates
call phpsdk_deps --check --deps C:\build-cache\deps
rem if errorlevel 7 call phpsdk_deps -d C:\build-cache\deps -un

echo ### Invoking phpize
call phpize
if errorlevel 1 exit /b %ERRORLEVEL%

echo ### Invoking configure
call configure --enable-debug-pack --with-mp=auto --with-php-build=C:\build-cache\deps --with-amqp
if errorlevel 1 exit /b %ERRORLEVEL%
exit /b 0

echo ### Invoking nmake
nmake /nologo .
exit /b %ERRORLEVEL%

echo ## Built

"@

& "C:\build-cache\php-sdk\phpsdk-$vcVersionPart-$($phpInfo.Architecture).bat" -t .\task.bat
if (-not $?) {
    throw "build failed with errorlevel $LastExitCode"
}
