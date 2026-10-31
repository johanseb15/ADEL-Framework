$ErrorActionPreference = 'Stop'
$runner = Join-Path $PSScriptRoot 'Run-Tests.ps1'
$tokens = $null
$errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile($runner, [ref]$tokens, [ref]$errors)
if ($errors.Count) { throw 'Runner has parse errors' }
$check = $ast.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Check' }, $true)
if (-not $check) { throw 'Check function not found' }
Invoke-Expression $check.Extent.Text
$omit = $ast.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Omit-Check' }, $true)
if (-not $omit) { throw 'Omit-Check function not found' }
Invoke-Expression $omit.Extent.Text

$cases = @(
  @{ Name = 'pass'; Body = { }; Expected = 'PASS probe'; Counts = @(1, 0, 0, 0) },
  @{ Name = 'fail'; Body = { throw 'broken' }; Expected = 'FAIL probe'; Counts = @(0, 1, 0, 0) },
  @{ Name = 'internal fail'; Body = { @{ Status = 'FAIL'; Reason = 'broken' } }; Expected = 'FAIL probe'; Counts = @(0, 1, 0, 0) },
  @{ Name = 'blocked'; Body = { Omit-Check 'required tool unavailable' $true }; Expected = 'BLOCKED probe'; Counts = @(0, 0, 1, 0) },
  @{ Name = 'skip'; Body = { Omit-Check 'optional tool unavailable' $false }; Expected = 'SKIP probe'; Counts = @(0, 0, 0, 1) }
)
foreach ($case in $cases) {
  $script:passed = 0; $script:failed = 0; $script:blocked = 0; $script:skipped = 0
  $output = Check 'probe' $case.Body 6>&1 | Out-String
  $actual = @($passed, $failed, $blocked, $skipped)
  if ($output -notmatch [regex]::Escape($case.Expected)) { throw "Resultado $($case.Name) incorrecto: $output" }
  if ($output -match '(?m)^\s*(PASS|FAIL|BLOCKED|SKIP) probe' -and @([regex]::Matches($output, '(?m)^\s*(PASS|FAIL|BLOCKED|SKIP) probe')).Count -ne 1) { throw "Estados duplicados: $output" }
  if (($actual -join ',') -ne ($case.Counts -join ',')) { throw "Conteos $($case.Name): $($actual -join ',')" }
}

$tail = ($ast.EndBlock.Statements | Select-Object -Last 2 | ForEach-Object { $_.Extent.Text }) -join "`r`n"
$prelude = '$passed=0; $failed=0; $blocked=0; $skipped=0' + "`r`n" + $check.Extent.Text + "`r`n" + $omit.Extent.Text
$scenarios = @(
  @{ Name = 'pass and skip'; Calls = "Check 'pass' { }; Check 'skip' { Omit-Check 'optional' `$false }"; Counts = 'PASS=1 FAIL=0 BLOCKED=0 SKIP=1'; Exit = 0 },
  @{ Name = 'pass and blocked'; Calls = "Check 'pass' { }; Check 'blocked' { Omit-Check 'required' `$true }"; Counts = 'PASS=1 FAIL=0 BLOCKED=1 SKIP=0'; Exit = 1 },
  @{ Name = 'fail and skip'; Calls = "Check 'fail' { throw 'broken' }; Check 'skip' { Omit-Check 'optional' `$false }"; Counts = 'PASS=0 FAIL=1 BLOCKED=0 SKIP=1'; Exit = 1 },
  @{ Name = 'all outcomes'; Calls = "Check 'pass' { }; Check 'fail' { throw 'broken' }; Check 'blocked' { Omit-Check 'required' `$true }; Check 'skip' { Omit-Check 'optional' `$false }"; Counts = 'PASS=1 FAIL=1 BLOCKED=1 SKIP=1'; Exit = 1 }
)
foreach ($scenario in $scenarios) {
  $fixture = Join-Path ([System.IO.Path]::GetTempPath()) ('adel-runner-outcome-' + [guid]::NewGuid().ToString('N') + '.ps1')
  try {
    Set-Content -LiteralPath $fixture -Value ($prelude + "`r`n" + $scenario.Calls + "`r`n" + $tail) -Encoding UTF8
    $output = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $fixture 6>&1 | Out-String
    $code = $LASTEXITCODE
    if ($code -ne $scenario.Exit) { throw "Salida $($scenario.Name): esperada $($scenario.Exit), obtenida $code. $output" }
    if ($output -notmatch [regex]::Escape($scenario.Counts)) { throw "Resumen $($scenario.Name) incorrecto: $output" }
    if ($output -match 'All tests passed' -and $scenario.Exit -ne 0) { throw "Falso GREEN en $($scenario.Name): $output" }
  } finally { Remove-Item -LiteralPath $fixture -Force -ErrorAction SilentlyContinue }
}
Write-Host 'PASS runner outcomes: PASS, FAIL, BLOCKED, SKIP y combinaciones'
