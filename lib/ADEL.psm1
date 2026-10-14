Set-StrictMode -Version Latest

function Get-AdelManifest([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "Manifest missing: $Path" }
  $manifest = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
  if ($manifest.schemaVersion -ne 1 -or -not $manifest.profiles -or -not $manifest.tools) { throw 'Invalid manifest schema' }
  return $manifest
}
function Get-AdelProfile($Manifest, [string]$Name) {
  $property = $Manifest.profiles.PSObject.Properties[$Name]
  if (-not $property) { throw "Unknown profile: $Name" }
  foreach ($id in $property.Value) {
    if (-not $Manifest.tools.PSObject.Properties[$id]) { throw "Unknown tool in profile: $id" }
  }
  return @($property.Value)
}
function Compare-AdelVersion([string]$Actual, [string]$Minimum) {
  $a = [regex]::Match($Actual, '(\d+)\.(\d+)\.(\d+)')
  $b = [regex]::Match($Minimum, '(\d+)\.(\d+)\.(\d+)')
  if (-not $a.Success -or -not $b.Success) { return -1 }
  for ($i = 1; $i -le 3; $i++) {
    $difference = [int]$a.Groups[$i].Value - [int]$b.Groups[$i].Value
    if ($difference -ne 0) { return [Math]::Sign($difference) }
  }
  return 0
}
function Get-AdelSkillRoot([string]$SkillsRoot) {
  if ($SkillsRoot) { return [System.IO.Path]::GetFullPath($SkillsRoot) }
  $codexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $env:USERPROFILE '.codex' }
  return Join-Path $codexHome 'skills'
}
function Get-AdelProbe($Manifest, [string]$Root, [string]$SkillsRoot = '') {
  $result = @{}
  $commands = @{git='git.exe'; node='node.exe'; pnpm='pnpm.cmd'; codex='codex.cmd'}
  foreach ($id in $commands.Keys) {
    if (Get-Command $commands[$id] -ErrorAction SilentlyContinue) {
      try {
        $previousPreference = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        $output = & $commands[$id] --version 2>&1
        if ($LASTEXITCODE -eq 0) {
          $line = @($output) | Where-Object { $_ -is [string] -and $_ -match '\d+\.\d+\.\d+' } | Select-Object -First 1
          if ($line) { $result[$id] = [string]$line }
        }
      } catch { }
      finally { $ErrorActionPreference = $previousPreference }
    }
  }
  $super = Join-Path $Root 'superpowers'
  $skill = Join-Path $env:USERPROFILE '.agents\skills\superpowers\using-superpowers\SKILL.md'
  if ((Test-Path -LiteralPath (Join-Path $super '.git')) -and (Test-Path -LiteralPath $skill)) {
    try {
      $tag = & git.exe -C $super describe --tags --exact-match 2>$null
      $commit = & git.exe -C $super rev-parse HEAD 2>$null
      if ($LASTEXITCODE -eq 0 -and $commit -eq $Manifest.tools.superpowers.gitCommit -and $tag -match '^v(\d+\.\d+\.\d+)$') { $result.superpowers = $Matches[1] }
    } catch { }
  }
  if (-not $result.ContainsKey('superpowers')) {
    $version = $Manifest.tools.superpowers.version
    $cache = Join-Path $env:USERPROFILE ".codex\plugins\cache\openai-curated-remote\superpowers\$version"
    $cachedSkill = Join-Path $cache 'skills\using-superpowers\SKILL.md'
    $cachedManifest = Join-Path $cache '.codex-plugin\plugin.json'
    if ((Test-Path -LiteralPath $cachedSkill) -and (Test-Path -LiteralPath $cachedManifest)) {
      try {
        $plugin = Get-Content -LiteralPath $cachedManifest -Raw | ConvertFrom-Json
        if ($plugin.version -eq $version) { $result.superpowers = "cache:$version" }
      } catch { }
    }
  }
  $template = Join-Path (Split-Path $PSScriptRoot -Parent) 'templates\react-vite-ts\package.json'
  if (Test-Path -LiteralPath $template) { $result['template-react'] = '1.0.0' }
  $skillHome = Get-AdelSkillRoot $SkillsRoot
  foreach ($id in @('frontend-design','ui-ux-pro-max')) {
    $tool = $Manifest.tools.PSObject.Properties[$id].Value
    $repo = Join-Path $Root "skills\$id"
    $source = if ($id -eq 'ui-ux-pro-max') { Join-Path $Root "materialized-skills\$id" } else { Join-Path $repo $tool.skillPath }
    $link = Join-Path $skillHome $id
    if (-not (Test-Path -LiteralPath (Join-Path $source 'SKILL.md')) -or -not (Test-Path -LiteralPath (Join-Path $link 'SKILL.md'))) { continue }
    if ($id -eq 'ui-ux-pro-max' -and (-not (Test-Path -LiteralPath (Join-Path $source 'scripts\search.py') -PathType Leaf) -or -not (Test-Path -LiteralPath (Join-Path $source 'data\colors.csv') -PathType Leaf))) { continue }
    try {
      if ($id -eq 'ui-ux-pro-max') {
        $pairs = @(
          @((Join-Path $source 'SKILL.md'), (Join-Path $repo "$($tool.skillPath)\SKILL.md")),
          @((Join-Path $source 'scripts\search.py'), (Join-Path $repo 'src\ui-ux-pro-max\scripts\search.py')),
          @((Join-Path $source 'data\colors.csv'), (Join-Path $repo 'src\ui-ux-pro-max\data\colors.csv'))
        )
        $matches = $true
        foreach ($pair in $pairs) {
          if ((Get-FileHash -LiteralPath $pair[0] -Algorithm SHA256).Hash -ne (Get-FileHash -LiteralPath $pair[1] -Algorithm SHA256).Hash) { $matches = $false; break }
        }
        if (-not $matches) { continue }
      }
      $item = Get-Item -LiteralPath $link -Force
      $resolvedSource = [System.IO.Path]::GetFullPath($source).TrimEnd('\')
      $resolvedTarget = [System.IO.Path]::GetFullPath([string]$item.Target).TrimEnd('\')
      $commit = & git.exe -c "safe.directory=$repo" -C $repo rev-parse HEAD 2>$null
      if ($item.LinkType -eq 'Junction' -and $resolvedTarget -eq $resolvedSource -and $LASTEXITCODE -eq 0 -and $commit -eq $tool.gitCommit) {
        $result[$id] = "source:$commit"
      }
    } catch { }
  }
  return $result
}
function Get-AdelStatuses($Manifest, [string]$Profile, [hashtable]$Probe) {
  $statuses = @{}
  foreach ($id in (Get-AdelProfile $Manifest $Profile)) {
    $tool = $Manifest.tools.PSObject.Properties[$id].Value
    $value = if ($Probe.ContainsKey($id)) { [string]$Probe[$id] } else { $null }
    $status = 'UNAVAILABLE'
    if ($tool.scope -eq 'capability' -and -not $value) { $status = 'LIMITED' }
    if ($value) {
      $status = 'AVAILABLE'
      if ($value.StartsWith('cache:')) { $status = 'LIMITED' }
      if ($tool.scope -eq 'skill' -and $id -in @('frontend-design','ui-ux-pro-max') -and $value -ne "source:$($tool.gitCommit)") { $status = 'LIMITED' }
      if ($tool.PSObject.Properties['minimum'] -and (Compare-AdelVersion $value $tool.minimum) -lt 0) { $status = 'LIMITED' }
    }
    $statuses[$id] = [pscustomobject]@{ status=$status; version=$value; scope=$tool.scope; required=[bool]$tool.required }
  }
  return $statuses
}
function Get-AdelInstallPlan($Manifest, [string]$Profile, [hashtable]$Probe) {
  $statuses = Get-AdelStatuses $Manifest $Profile $Probe
  foreach ($id in (Get-AdelProfile $Manifest $Profile)) {
    $tool = $Manifest.tools.PSObject.Properties[$id].Value
    if ($statuses[$id].status -ne 'AVAILABLE' -and $tool.required -and $Probe[$id] -notmatch '^cache:' -and ($tool.PSObject.Properties['wingetId'] -or $tool.PSObject.Properties['npmPackage'] -or $tool.PSObject.Properties['gitUrl'])) { $id }
  }
}
Export-ModuleMember -Function Get-AdelManifest,Get-AdelProfile,Compare-AdelVersion,Get-AdelSkillRoot,Get-AdelProbe,Get-AdelStatuses,Get-AdelInstallPlan
