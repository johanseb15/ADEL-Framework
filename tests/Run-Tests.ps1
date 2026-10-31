param([string]$Root = (Split-Path $PSScriptRoot -Parent))
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $Root 'lib/ADEL.psm1') -Force
$failed = 0
$passed = 0
$blocked = 0
$skipped = 0
function Check($name, [scriptblock]$body) {
  try {
    $emitted = @(& $body)
    $outcome = $null
    foreach ($result in $emitted) {
      if ($result -is [hashtable] -and @('FAIL', 'BLOCKED', 'SKIP') -contains $result.Status) { $outcome = $result }
      else { Write-Output $result }
    }
    if ($outcome) {
      switch ($outcome.Status) {
        'FAIL' { $script:failed++ }
        'BLOCKED' { $script:blocked++ }
        'SKIP' { $script:skipped++ }
      }
      Write-Host "$($outcome.Status) $name`: $($outcome.Reason)"
    } else {
      $script:passed++
      Write-Host "PASS $name"
    }
  }
  catch { $script:failed++; Write-Host "FAIL $name`: $_" }
}
function Omit-Check($reason, [bool]$required) {
  if ($required) { return @{ Status = 'BLOCKED'; Reason = $reason } }
  return @{ Status = 'SKIP'; Reason = $reason }
}
function Assert($condition, $message) { if (-not $condition) { throw $message } }
$manifest = Get-AdelManifest (Join-Path $Root 'adel.tools.json')
Assert ($manifest.tools.superpowers.gitCommit -match '^[a-f0-9]{40}$') 'Superpowers commit is not pinned'

Check 'profiles are explicit and nested' {
  $minimal = Get-AdelProfile $manifest 'minimal'
  $web = Get-AdelProfile $manifest 'web-app'
  $visual = Get-AdelProfile $manifest 'visual-game'
  Assert ($minimal -contains 'superpowers') 'minimal lacks Superpowers'
  Assert ($web -contains 'template-react') 'web-app lacks template'
  Assert ($visual -contains 'imagegen' -and $visual -contains 'browser' -and $visual -contains 'product-design') 'visual options absent'
  Assert ($minimal.Count -lt $web.Count -and $web.Count -lt $visual.Count) 'profiles not nested'
}
Check 'versions are compared numerically' {
  Assert ((Compare-AdelVersion 'v24.19.0' '24.15.0') -ge 0) 'new version rejected'
  Assert ((Compare-AdelVersion '2.9.0' '2.10.0') -lt 0) 'lexical comparison used'
}
Check 'Codex versions respect manifest minimum' {
  $minimum = $manifest.tools.codex.minimum
  Assert ((Compare-AdelVersion '0.164.0' $minimum) -ge 0) 'compatible Codex version rejected'
  Assert ((Compare-AdelVersion '0.156.0' $minimum) -lt 0) 'inferior Codex version accepted'
  Assert ((Compare-AdelVersion 'invalid' $minimum) -lt 0) 'invalid Codex version accepted'
  Assert ((Compare-AdelVersion $null $minimum) -lt 0) 'absent Codex version accepted'
}
Check 'doctor distinguishes available limited missing' {
  $probe = @{ git = '2.55.0'; node = '24.19.0'; pnpm = '10.0.0' }
  $result = Get-AdelStatuses $manifest 'minimal' $probe
  Assert ($result.git.status -eq 'AVAILABLE') 'git wrong'
  Assert ($result.pnpm.status -eq 'LIMITED') 'pnpm wrong'
  Assert ($result.codex.status -eq 'UNAVAILABLE') 'codex wrong'
}
Check 'real probe captures version of available commands that exit successfully' {
  $probe = Get-AdelProbe $manifest (Join-Path ([System.IO.Path]::GetTempPath()) 'adel-test-probe')
  Assert ($probe.node -match '24\.') 'node version not captured'
  Assert ($probe.pnpm -match '11\.') 'pnpm version not captured'
  if (Get-Command codex.cmd -ErrorAction SilentlyContinue) {
    Assert ($probe.codex) 'codex version not captured despite executable'
    Assert ((Compare-AdelVersion $probe.codex $manifest.tools.codex.minimum) -ge 0) 'codex version below manifest minimum'
  } else {
    # La prueba real de Codex es opcional; las comparaciones de versión anteriores siguen siendo obligatorias.
    Omit-Check 'codex.cmd is not detectable in this environment' $false
  }
}
Check 'installer plan is idempotent and WhatIf does not mutate' {
  $probe = @{ git = '2.55.0'; node = '24.19.0'; pnpm = '11.9.0'; codex = '0.157.0'; superpowers = '6.4.2' }
  $actions = @(Get-AdelInstallPlan $manifest 'minimal' $probe)
  Assert ($actions.Count -eq 0) 'reinstall scheduled'
  $output = & (Join-Path $Root 'install.ps1') -Profile minimal -WhatIf -ProbeOverride $probe
  Assert ($output -contains 'No installations needed.') 'WhatIf changed install plan'
  $installRootCandidate = Join-Path ([System.IO.Path]::GetTempPath()) ('adel-install-test-' + [guid]::NewGuid().ToString('N'))
  & (Join-Path $Root 'install.ps1') -Profile minimal -InstallRoot $installRootCandidate -WhatIf -ProbeOverride @{} | Out-Null
  Assert (-not (Test-Path -LiteralPath $installRootCandidate)) 'WhatIf created install root'
}
Check 'cached Superpowers is limited and does not trigger duplicate install' {
  $probe = @{ git='2.55.0'; node='24.19.0'; pnpm='11.9.0'; codex='0.157.0'; superpowers='cache:6.4.2' }
  $statuses = Get-AdelStatuses $manifest 'minimal' $probe
  Assert ($statuses.superpowers.status -eq 'LIMITED') 'cache treated as installed'
  Assert (@(Get-AdelInstallPlan $manifest 'minimal' $probe).Count -eq 0) 'duplicate install planned'
  $preview = & (Join-Path $Root 'install.ps1') -Profile minimal -WhatIf -InstallSuperpowersFromSource -ProbeOverride $probe
  Assert (($preview -join ' ') -match 'Run doctor') 'explicit source install not previewed'
}
Check 'session-only capabilities are unknown without confirmation' {
  $statuses = Get-AdelStatuses $manifest 'visual-game' @{}
  Assert ($statuses.browser.status -eq 'LIMITED') 'browser falsely declared absent'
  Assert ($statuses.imagegen.status -eq 'LIMITED') 'ImageGen falsely declared absent'
  Assert ($statuses['product-design'].status -eq 'LIMITED') 'Product Design falsely declared absent'
}
Check 'unknown profile is rejected' {
  $threw = $false
  try { Get-AdelProfile $manifest 'other' | Out-Null } catch { $threw = $true }
  Assert $threw 'unknown profile accepted'
}
Check 'new project respects WhatIf and refuses overwrite' {
  $target = Join-Path ([System.IO.Path]::GetTempPath()) ('adel-test-' + [guid]::NewGuid().ToString('N'))
  try {
    & (Join-Path $Root 'new-project.ps1') -Name 'sample-app' -Path $target -WhatIf | Out-Null
    Assert (-not (Test-Path -LiteralPath $target)) 'WhatIf created files'
    & (Join-Path $Root 'new-project.ps1') -Name 'sample-app' -Path $target | Out-Null
    Assert (Test-Path -LiteralPath (Join-Path $target 'src/App.tsx')) 'template missing'
    Assert (Test-Path -LiteralPath (Join-Path $target 'pnpm-lock.yaml')) 'default lockfile missing'
    Assert ((Get-Content -LiteralPath (Join-Path $target 'package.json') -Raw | ConvertFrom-Json).name -eq 'sample-app') 'default package name changed'
    $threw = $false
    try { & (Join-Path $Root 'new-project.ps1') -Name 'sample-app' -Path $target | Out-Null } catch { $threw = $true }
    Assert $threw 'existing project overwritten'
  } finally {
    $tempRoot = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath())
    if ($target.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase) -and (Test-Path -LiteralPath $target)) { Remove-Item -LiteralPath $target -Recurse -Force }
  }
}
Check 'python CLI template is independent of the web toolchain' {
  $target = Join-Path ([System.IO.Path]::GetTempPath()) ('adel python test ' + [guid]::NewGuid().ToString('N'))
  try {
    $threw = $false
    try { & (Join-Path $Root 'new-project.ps1') -Name 'sample-cli' -Path $target -Template python-cli -InstallDependencies | Out-Null } catch { $threw = $true }
    Assert $threw 'Python template accepted dependency installation'
    Assert (-not (Test-Path -LiteralPath $target)) 'rejected dependency installation created files'
    & (Join-Path $Root 'new-project.ps1') -Name 'sample-cli' -Path $target -Template python-cli -WhatIf | Out-Null
    Assert (-not (Test-Path -LiteralPath $target)) 'Python WhatIf created files'
    & (Join-Path $Root 'new-project.ps1') -Name 'sample-cli' -Path $target -Template python-cli | Out-Null
    Assert (Test-Path -LiteralPath (Join-Path $target 'main.py')) 'Python entry point missing'
    Assert (Test-Path -LiteralPath (Join-Path $target 'tests/test_main.py')) 'Python tests missing'
    foreach ($webFile in @('package.json', 'pnpm-lock.yaml', 'vite.config.ts', 'src/App.tsx')) {
      Assert (-not (Test-Path -LiteralPath (Join-Path $target $webFile))) "Web artifact copied: $webFile"
    }
    $python = Get-Command python.exe, py.exe -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($python) {
      Push-Location $target
      try {
        if ($python.Name -eq 'py.exe') { & $python.Source -3 -m unittest discover -s tests }
        else { & $python.Source -m unittest discover -s tests }
        Assert ($LASTEXITCODE -eq 0) 'generated Python tests failed'
      } finally { Pop-Location }
    } else {
      # Ejecutar los tests generados de Python es obligatorio para verificar esta plantilla.
      Omit-Check 'Python interpreter is unavailable' $true
    }
    $threw = $false
    try { & (Join-Path $Root 'new-project.ps1') -Name 'sample-cli' -Path $target -Template python-cli | Out-Null } catch { $threw = $true }
    Assert $threw 'existing Python project overwritten'
  } finally {
    $tempRoot = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath())
    if ($target.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase) -and (Test-Path -LiteralPath $target)) { Remove-Item -LiteralPath $target -Recurse -Force }
  }
}
Check 'unknown project template is rejected before creating a destination' {
  $target = Join-Path ([System.IO.Path]::GetTempPath()) ('adel-unknown-test-' + [guid]::NewGuid().ToString('N'))
  $threw = $false
  try { & (Join-Path $Root 'new-project.ps1') -Name 'sample-cli' -Path $target -Template unknown | Out-Null }
  catch { $threw = $_.Exception.Message -match 'ValidateSet|validation|validación|does not belong to the set' }
  Assert $threw 'unknown template accepted'
  Assert (-not (Test-Path -LiteralPath $target)) 'unknown template created destination'
}
Check 'visual sources are pinned and isolated from minimal' {
  $visual = Get-AdelProfile $manifest 'visual-game'
  $minimal = Get-AdelProfile $manifest 'minimal'
  foreach ($id in @('frontend-design','ui-ux-pro-max')) {
    Assert ($visual -contains $id -and $minimal -notcontains $id) "$id profile placement wrong"
    $tool = $manifest.tools.PSObject.Properties[$id].Value
    Assert ($tool.gitCommit -match '^[a-f0-9]{40}$') "$id commit not pinned"
    Assert ($tool.skillPath -and $tool.gitUrl) "$id source incomplete"
  }
}
Check 'visual skills are planned once and diagnosed by verified source' {
  $probe = @{git='2.55.0';node='24.19.0';pnpm='11.9.0';codex='0.157.0';superpowers='6.4.2';'template-react'='1.0.0'}
  $plan = @(Get-AdelInstallPlan $manifest 'visual-game' $probe)
  Assert ($plan -contains 'frontend-design' -and $plan -contains 'ui-ux-pro-max') 'visual skills missing from plan'
  $probe['frontend-design'] = 'source:' + $manifest.tools.'frontend-design'.gitCommit
  $probe['ui-ux-pro-max'] = 'source:' + $manifest.tools.'ui-ux-pro-max'.gitCommit
  $status = Get-AdelStatuses $manifest 'visual-game' $probe
  Assert ($status['frontend-design'].status -eq 'AVAILABLE') 'frontend skill not available'
  Assert ($status['ui-ux-pro-max'].status -eq 'AVAILABLE') 'UI skill not available'
  Assert (@(Get-AdelInstallPlan $manifest 'visual-game' $probe).Count -eq 0) 'duplicate skill installation planned'
  $probe['frontend-design'] = 'cache:unknown'
  Assert ((Get-AdelStatuses $manifest 'visual-game' $probe)['frontend-design'].status -eq 'LIMITED') 'cache falsely verified'
}
Check 'visual WhatIf and doctor report without writes' {
  $target = Join-Path ([System.IO.Path]::GetTempPath()) ('adel-visual-test-' + [guid]::NewGuid().ToString('N'))
  $preview = & (Join-Path $Root 'install.ps1') -Profile visual-game -InstallRoot $target -WhatIf -ProbeOverride @{}
  Assert (-not (Test-Path -LiteralPath $target)) 'visual WhatIf wrote install root'
  Assert (@(Get-AdelInstallPlan $manifest 'visual-game' @{}) -contains 'frontend-design') 'visual preview plan missing skill'
  $rows = & (Join-Path $Root 'doctor.ps1') -Profile visual-game -Json -ProbeOverride @{} | ConvertFrom-Json
  Assert (($rows | Where-Object tool -eq 'frontend-design').status -eq 'UNAVAILABLE') 'doctor skill diagnosis wrong'
}
Check 'generated template has sequential browser workflow' {
  $package = Get-Content (Join-Path $Root 'templates/react-vite-ts/package.json') -Raw | ConvertFrom-Json
  Assert ($package.devDependencies.'@playwright/test' -match '^1\.64\.0$') 'Playwright not pinned'
  Assert ($package.scripts.'test:windows' -match 'test:run.*test:e2e') 'tests not sequential'
  Assert (Test-Path (Join-Path $Root 'templates/react-vite-ts/e2e/smoke.spec.ts')) 'E2E missing'
  Assert (Test-Path (Join-Path $Root 'templates/react-vite-ts/scripts/verify-chromium.mjs')) 'Chromium verifier missing'
}
Check 'doctor distinguishes missing project browser from hosted browser capability' {
  $missing = Join-Path ([System.IO.Path]::GetTempPath()) ('adel-missing-project-' + [guid]::NewGuid().ToString('N'))
  $rows = & (Join-Path $Root 'doctor.ps1') -Profile visual-game -ProjectPath $missing -Json -ProbeOverride @{} | ConvertFrom-Json
  Assert (($rows | Where-Object tool -eq 'chromium-project').status -eq 'UNAVAILABLE') 'missing Chromium falsely available'
  Assert (($rows | Where-Object tool -eq 'browser').status -eq 'LIMITED') 'hosted Browser confused with Chromium'
  Assert (-not (Test-Path -LiteralPath $missing)) 'doctor wrote to missing project'
}
Check 'generated React project carries an actionable visual contract and agent gate' {
  $target = Join-Path ([System.IO.Path]::GetTempPath()) ('adel-art-test-' + [guid]::NewGuid().ToString('N'))
  try {
    & (Join-Path $Root 'new-project.ps1') -Name 'art-test' -Path $target | Out-Null
    $contractPath = Join-Path $target 'docs/ART-DIRECTION.md'
    $agentPath = Join-Path $target 'AGENTS.md'
    Assert (Test-Path -LiteralPath $contractPath) 'generated React project lacks its visual contract'
    Assert (Test-Path -LiteralPath $agentPath) 'generated React project lacks agent instructions'
    $contract = Get-Content -LiteralPath $contractPath -Raw -Encoding UTF8
    $agents = Get-Content -LiteralPath $agentPath -Raw -Encoding UTF8
    foreach ($term in @('responsable', 'fuente', 'fecha', 'medio', 'referencia', 'prohibiciones', 'prototipo', 'candidato', 'final aprobado', 'tipograf', 'legibilidad', 'responsive', 'accesibilidad', 'coherencia')) {
      Assert ($contract -match $term) "visual contract lacks $term"
    }
    Assert ($contract -match 'QA t.cnico' -and $contract -match 'aprobaci.n art.stica') 'technical QA and human art approval are not separate'
    Assert ($agents -match 'docs/ART-DIRECTION.md') 'agents do not read the project contract'
    Assert ($agents -match 'placeholder' -and $agents -match 'final aprobado') 'agents do not distinguish provisional and approved art'
    Assert ($agents -match 'responsable' -and $agents -match 'aprobaci.n') 'agent approval authority is unclear'
  } finally {
    $tempRoot = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath())
    if ($target.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase) -and (Test-Path -LiteralPath $target)) { Remove-Item -LiteralPath $target -Recurse -Force }
  }
}
Write-Host "Results: PASS=$passed FAIL=$failed BLOCKED=$blocked SKIP=$skipped"
if ($failed -or $blocked) { exit 1 }
