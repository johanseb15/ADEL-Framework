[CmdletBinding(SupportsShouldProcess)]
param(
  [ValidateSet('minimal','web-app','visual-game')][string]$Profile = 'minimal',
  [string]$InstallRoot = (Join-Path $env:LOCALAPPDATA 'ADEL'),
  [string]$SkillsRoot = '',
  [switch]$InstallSuperpowersFromSource
)
$ErrorActionPreference = 'Stop'
$args = @{ Profile=$Profile; InstallRoot=$InstallRoot; SkillsRoot=$SkillsRoot }
if ($WhatIfPreference) { $args.WhatIf = $true }
if ($InstallSuperpowersFromSource) { $args.InstallSuperpowersFromSource = $true }
& (Join-Path $PSScriptRoot 'install.ps1') @args
if ($WhatIfPreference) { Write-Output 'WhatIf: diagnostic of the current machine follows.' }
& (Join-Path $PSScriptRoot 'doctor.ps1') -Profile $Profile -InstallRoot $InstallRoot -SkillsRoot $SkillsRoot
