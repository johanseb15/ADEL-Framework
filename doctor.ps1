[CmdletBinding()]
param(
  [ValidateSet('minimal','web-app','visual-game')][string]$Profile = 'minimal',
  [string]$InstallRoot = (Join-Path $env:LOCALAPPDATA 'ADEL'),
  [string]$SkillsRoot = '',
  [string]$ProjectPath = '',
  [string[]]$Capabilities = @(),
  [switch]$Json,
  [hashtable]$ProbeOverride
)
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'lib/ADEL.psm1') -Force
$manifest = Get-AdelManifest (Join-Path $PSScriptRoot 'adel.tools.json')
$probe = if ($PSBoundParameters.ContainsKey('ProbeOverride')) { $ProbeOverride } else { Get-AdelProbe $manifest $InstallRoot $SkillsRoot }
foreach ($name in $Capabilities) {
  if ($name -notin @('browser','imagegen','product-design')) { throw "Unknown capability: $name" }
  $probe[$name] = 'available-in-current-session'
}
$statuses = Get-AdelStatuses $manifest $Profile $probe
$rows = foreach ($id in (Get-AdelProfile $manifest $Profile)) {
  [pscustomobject]@{ tool=$id; status=$statuses[$id].status; version=$statuses[$id].version; scope=$statuses[$id].scope; required=$statuses[$id].required }
}
if ($ProjectPath) {
  $project = [System.IO.Path]::GetFullPath($ProjectPath)
  $package = Join-Path $project 'package.json'
  $playwrightStatus = 'UNAVAILABLE'
  $chromiumStatus = 'UNAVAILABLE'
  $playwrightVersion = $null
  $chromiumVersion = $null
  if (Test-Path -LiteralPath $package) {
    $metadata = Get-Content -LiteralPath $package -Raw | ConvertFrom-Json
    if ($metadata.devDependencies.PSObject.Properties['@playwright/test']) {
      $playwrightVersion = [string]$metadata.devDependencies.'@playwright/test'
      $playwrightStatus = 'LIMITED'
      if (Test-Path -LiteralPath (Join-Path $project 'node_modules\@playwright\test\package.json')) {
        $playwrightStatus = 'AVAILABLE'
        if (Test-Path -LiteralPath (Join-Path $project 'scripts\verify-chromium.mjs')) {
          Push-Location $project
          try {
            $output = & node.exe 'scripts/verify-chromium.mjs' 2>&1
            if ($LASTEXITCODE -eq 0) { $chromiumStatus = 'AVAILABLE'; $chromiumVersion = (@($output) -join ' ').Trim() }
          } catch { $chromiumStatus = 'LIMITED' }
          finally { Pop-Location }
        }
      }
    }
  }
  $rows += [pscustomobject]@{ tool='playwright-project'; status=$playwrightStatus; version=$playwrightVersion; scope='project'; required=$true }
  $rows += [pscustomobject]@{ tool='chromium-project'; status=$chromiumStatus; version=$chromiumVersion; scope='project'; required=$true }
}
if ($Json) { $rows | ConvertTo-Json -Depth 4 } else { $rows | Format-Table -AutoSize | Out-String | Write-Output }
