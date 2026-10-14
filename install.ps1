[CmdletBinding(SupportsShouldProcess)]
param(
  [ValidateSet('minimal','web-app','visual-game')][string]$Profile = 'minimal',
  [string]$InstallRoot = (Join-Path $env:LOCALAPPDATA 'ADEL'),
  [string]$SkillsRoot = '',
  [switch]$InstallSuperpowersFromSource,
  [hashtable]$ProbeOverride
)
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'lib/ADEL.psm1') -Force
$manifest = Get-AdelManifest (Join-Path $PSScriptRoot 'adel.tools.json')
$probe = if ($PSBoundParameters.ContainsKey('ProbeOverride')) { $ProbeOverride } else { Get-AdelProbe $manifest $InstallRoot $SkillsRoot }
if ($InstallSuperpowersFromSource -and $probe.superpowers -match '^cache:') {
  $probe = $probe.Clone()
  $probe.Remove('superpowers')
}
$plan = @(Get-AdelInstallPlan $manifest $Profile $probe)
if (-not $plan.Count) { Write-Output 'No installations needed.'; return }
foreach ($id in $plan) {
  $tool = $manifest.tools.PSObject.Properties[$id].Value
  if (-not $PSCmdlet.ShouldProcess($id, "Install $($tool.version)")) { continue }
  switch ($id) {
    { $_ -in @('git','node') } {
      if (-not (Get-Command winget.exe -ErrorAction SilentlyContinue)) { throw "winget is required to install $id. Install App Installer, then rerun." }
      & winget.exe install --id $tool.wingetId --exact --version $tool.version --accept-package-agreements --accept-source-agreements
      if ($LASTEXITCODE -ne 0) { throw "winget failed installing $id (exit $LASTEXITCODE)" }
    }
    { $_ -in @('pnpm','codex') } {
      if (-not (Get-Command npm.cmd -ErrorAction SilentlyContinue)) { throw "npm.cmd missing. Install Node, reopen PowerShell, and rerun." }
      & npm.cmd install --global "$($tool.npmPackage)@$($tool.version)"
      if ($LASTEXITCODE -ne 0) { throw "npm failed installing $id (exit $LASTEXITCODE)" }
    }
    'superpowers' {
      if (-not (Get-Command git.exe -ErrorAction SilentlyContinue)) { throw 'git.exe missing. Install Git, reopen PowerShell, and rerun.' }
      $target = Join-Path $InstallRoot 'superpowers'
      $link = Join-Path $env:USERPROFILE '.agents\skills\superpowers'
      if (Test-Path -LiteralPath $link) { throw "Skill path exists but is not verified; refusing to replace: $link" }
      if (-not (Test-Path -LiteralPath $target)) {
        New-Item -ItemType Directory -Path $InstallRoot -Force | Out-Null
        $stage = Join-Path $InstallRoot ('.superpowers-stage-' + [guid]::NewGuid().ToString('N'))
        try {
          & git.exe clone --depth 1 --branch $tool.gitTag $tool.gitUrl $stage
          if ($LASTEXITCODE -ne 0) { throw "Superpowers clone failed (exit $LASTEXITCODE)" }
          $stageCommit = & git.exe -C $stage rev-parse HEAD
          if ($LASTEXITCODE -ne 0 -or $stageCommit -ne $tool.gitCommit) { throw "Superpowers source commit mismatch: $stageCommit" }
          $rootPath = [System.IO.Path]::GetFullPath($InstallRoot).TrimEnd('\') + '\'
          $stagePath = [System.IO.Path]::GetFullPath($stage)
          $targetPath = [System.IO.Path]::GetFullPath($target)
          if (-not $stagePath.StartsWith($rootPath, [StringComparison]::OrdinalIgnoreCase) -or -not $targetPath.StartsWith($rootPath, [StringComparison]::OrdinalIgnoreCase)) { throw 'Superpowers paths escaped install root' }
          Move-Item -LiteralPath $stage -Destination $target -ErrorAction Stop
        } finally {
          $rootPath = [System.IO.Path]::GetFullPath($InstallRoot).TrimEnd('\') + '\'
          $stagePath = [System.IO.Path]::GetFullPath($stage)
          if ($stagePath.StartsWith($rootPath, [StringComparison]::OrdinalIgnoreCase) -and (Test-Path -LiteralPath $stagePath)) {
            Remove-Item -LiteralPath $stagePath -Recurse -Force
          }
        }
      }
      $tag = & git.exe -C $target describe --tags --exact-match
      if ($LASTEXITCODE -ne 0 -or $tag -ne $tool.gitTag) { throw "Superpowers tag verification failed: $tag" }
      $commit = & git.exe -c "safe.directory=$target" -C $target rev-parse HEAD
      if ($LASTEXITCODE -ne 0 -or $commit -ne $tool.gitCommit) { throw "Superpowers commit verification failed: $commit" }
      $parent = Split-Path $link -Parent
      New-Item -ItemType Directory -Path $parent -Force | Out-Null
      New-Item -ItemType Junction -Path $link -Target (Join-Path $target 'skills') | Out-Null
      if (-not (Test-Path -LiteralPath (Join-Path $link 'using-superpowers\SKILL.md'))) { throw 'Superpowers skill discovery check failed' }
    }
    { $_ -in @('frontend-design','ui-ux-pro-max') } {
      if (-not (Get-Command git.exe -ErrorAction SilentlyContinue)) { throw 'git.exe is required for pinned skill installation' }
      $skillHome = Get-AdelSkillRoot $SkillsRoot
      $link = Join-Path $skillHome $id
      $target = Join-Path $InstallRoot "skills\$id"
      $source = if ($id -eq 'ui-ux-pro-max') { Join-Path $InstallRoot "materialized-skills\$id" } else { Join-Path $target $tool.skillPath }
      if (Test-Path -LiteralPath $link) { throw "Existing Codex skill is unverified; refusing to replace: $link" }
      if (-not (Test-Path -LiteralPath $target)) {
        $parent = Split-Path $target -Parent
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
        $stage = Join-Path $parent (".$id-stage-" + [guid]::NewGuid().ToString('N'))
        try {
          & git.exe init -q $stage
          if ($LASTEXITCODE -ne 0) { throw "git init failed for $id" }
          & git.exe -C $stage remote add origin $tool.gitUrl
          if ($LASTEXITCODE -ne 0) { throw "git remote failed for $id" }
          & git.exe -C $stage fetch --depth 1 origin $tool.gitCommit
          if ($LASTEXITCODE -ne 0) { throw "git fetch failed for $id" }
          & git.exe -C $stage checkout --detach -q FETCH_HEAD
          if ($LASTEXITCODE -ne 0) { throw "git checkout failed for $id" }
          $commit = & git.exe -C $stage rev-parse HEAD
          if ($LASTEXITCODE -ne 0 -or $commit -ne $tool.gitCommit) { throw "Source commit mismatch for $id`: $commit" }
          if (-not (Test-Path -LiteralPath (Join-Path $stage "$($tool.skillPath)\SKILL.md"))) { throw "SKILL.md missing at pinned source for $id" }
          Move-Item -LiteralPath $stage -Destination $target -ErrorAction Stop
        } finally {
          $parentFull = [System.IO.Path]::GetFullPath($parent).TrimEnd('\') + '\'
          $stageFull = [System.IO.Path]::GetFullPath($stage)
          if ($stageFull.StartsWith($parentFull, [StringComparison]::OrdinalIgnoreCase) -and (Test-Path -LiteralPath $stageFull)) { Remove-Item -LiteralPath $stageFull -Recurse -Force }
        }
      }
      $commit = & git.exe -c "safe.directory=$target" -C $target rev-parse HEAD
      if ($LASTEXITCODE -ne 0 -or $commit -ne $tool.gitCommit) { throw "Existing source commit mismatch for $id`: $commit" }
      if ($id -eq 'ui-ux-pro-max' -and -not (Test-Path -LiteralPath $source)) {
        $materializedParent = Split-Path $source -Parent
        New-Item -ItemType Directory -Path $materializedParent -Force | Out-Null
        $materializedStage = Join-Path $materializedParent ('.$id-stage-' + [guid]::NewGuid().ToString('N'))
        try {
          New-Item -ItemType Directory -Path $materializedStage | Out-Null
          Copy-Item -LiteralPath (Join-Path $target "$($tool.skillPath)\SKILL.md") -Destination $materializedStage
          $payload = Join-Path $target 'src\ui-ux-pro-max'
          foreach ($part in @('data','scripts')) { Copy-Item -LiteralPath (Join-Path $payload $part) -Destination $materializedStage -Recurse }
          if (-not (Test-Path -LiteralPath (Join-Path $materializedStage 'scripts\search.py')) -or -not (Test-Path -LiteralPath (Join-Path $materializedStage 'data\colors.csv'))) { throw 'UI/UX Pro Max payload incomplete' }
          Move-Item -LiteralPath $materializedStage -Destination $source
        } finally {
          $parentFull = [System.IO.Path]::GetFullPath($materializedParent).TrimEnd('\') + '\'
          $stageFull = [System.IO.Path]::GetFullPath($materializedStage)
          if ($stageFull.StartsWith($parentFull, [StringComparison]::OrdinalIgnoreCase) -and (Test-Path -LiteralPath $stageFull)) { Remove-Item -LiteralPath $stageFull -Recurse -Force }
        }
      }
      if (-not (Test-Path -LiteralPath (Join-Path $source 'SKILL.md'))) { throw "SKILL.md missing for $id" }
      if ($id -eq 'ui-ux-pro-max' -and (-not (Test-Path -LiteralPath (Join-Path $source 'scripts\search.py')) -or -not (Test-Path -LiteralPath (Join-Path $source 'data\colors.csv')))) { throw 'UI/UX Pro Max materialized payload missing' }
      New-Item -ItemType Directory -Path $skillHome -Force | Out-Null
      New-Item -ItemType Junction -Path $link -Target $source | Out-Null
      if (-not (Test-Path -LiteralPath (Join-Path $link 'SKILL.md'))) { throw "Codex discovery path failed for $id" }
    }
  }
  Write-Output "Installed $id."
}
Write-Output 'Run doctor.ps1 after restarting PowerShell and Codex to refresh PATH and skill discovery.'
