$ErrorActionPreference = 'Stop'
$root = Join-Path $env:RUNNER_TEMP ('wfd-probe-' + [guid]::NewGuid().ToString('N').Substring(0,8))
foreach ($d in @('.git\objects', 'node_modules\pkg', 'src\generated', 'src')) {
  New-Item -ItemType Directory -Force -Path (Join-Path $root $d) | Out-Null
}
foreach ($f in @('README.md', 'src\index.ts', '.git\config', '.git\objects\obj1', 'node_modules\pkg\index.js', 'src\generated\gen.ts')) {
  Set-Content -Path (Join-Path $root $f) -Value 'fixture'
}
Set-Location $root
function Test-Form {
  param($Label, $FindstrArgs)
  $cmd = 'dir /b /s /a:-d 2>nul | findstr /v /i ' + $FindstrArgs + ' | sort'
  $out = @(cmd.exe /c $cmd)
  $total = $out.Count
  $excluded = @($out | Where-Object { $_ -match '\\\.git\\|\\node_modules\\|\\src\\generated\\' })
  $verdict = if ($total -eq 2 -and $excluded.Count -eq 0) { 'PASS' } else { 'FAIL' }
  Write-Output ("FORM {0}: total={1} excluded={2} {3}" -f $Label, $total, $excluded.Count, $verdict)
  $out | ForEach-Object { Write-Output ("    " + $_) }
}
Test-Form 'A-current' '/c:"\.git\" /c:"\node_modules\" /c:"\src\generated\"'
Test-Form 'B-literal-doubled' '/l /c:"\\.git\\" /c:"\\node_modules\\" /c:"\\src\\generated\\"'
Test-Form 'C-literal-trailing-only' '/l /c:"\.git\\" /c:"\node_modules\\" /c:"\src\generated\\"'
Test-Form 'D-literal-single' '/l /c:"\.git\" /c:"\node_modules\" /c:"\src\generated\"'
$null = cmd.exe /c 'dir /b /a:-d 2>nul | sort /M 65536'
Write-Output ("SORT-M exit={0}" -f $LASTEXITCODE)
