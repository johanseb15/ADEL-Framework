[CmdletBinding(SupportsShouldProcess)]
param(
  [Parameter(Mandatory)][ValidatePattern('^[a-z][a-z0-9-]*$')][string]$Name,
  [Parameter(Mandatory)][string]$Path,
  [ValidateSet('react-vite-ts', 'python-cli')][string]$Template = 'react-vite-ts',
  [switch]$InstallDependencies
)
$ErrorActionPreference = 'Stop'
$target = [System.IO.Path]::GetFullPath($Path)
if (Test-Path -LiteralPath $target) { throw "Destination already exists: $target" }
$source = Join-Path (Join-Path $PSScriptRoot 'templates') $Template
if ($Template -eq 'react-vite-ts' -and -not (Test-Path -LiteralPath (Join-Path $source 'pnpm-lock.yaml'))) { throw 'Template lockfile missing' }
if ($Template -eq 'python-cli' -and $InstallDependencies) { throw 'python-cli has no dependencies to install' }
$description = if ($Template -eq 'react-vite-ts') { "Create React/Vite/TypeScript project $Name" } else { "Create Python CLI project $Name" }
if (-not $PSCmdlet.ShouldProcess($target, $description)) { return }
New-Item -ItemType Directory -Path $target -Force | Out-Null
try {
  Get-ChildItem -LiteralPath $source -Force | Copy-Item -Destination $target -Recurse -Force
  if ($Template -eq 'react-vite-ts') {
    $package = Join-Path $target 'package.json'
    $content = Get-Content -LiteralPath $package -Raw
    [System.IO.File]::WriteAllText($package, $content.Replace('adel-template-app', $Name), [System.Text.UTF8Encoding]::new($false))
  }
  if ($InstallDependencies) {
    if (-not (Get-Command pnpm.cmd -ErrorAction SilentlyContinue)) { throw 'pnpm.cmd is required for project dependencies' }
    Push-Location $target
    try { & pnpm.cmd install --frozen-lockfile; if ($LASTEXITCODE -ne 0) { throw "pnpm install failed (exit $LASTEXITCODE)" } }
    finally { Pop-Location }
  }
  Write-Output "Created $target"
} catch {
  throw "Project creation stopped at $target`: $_. Inspect or remove this new directory before retrying."
}
