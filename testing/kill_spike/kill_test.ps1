# Kill test for simple_file write_text (RQ-06 spike S-F2-1, K6 S2), re-run against simple_file itself.
# A writer rewrites one note in a tight loop and is killed (Stop-Process -Force = TerminateProcess) at a
# random moment 60-400 ms after start. Before each trial the note holds a complete "VERSION 0". After the
# kill the note is classified: complete (some whole version), empty (0 bytes), torn (anything else), missing.
# Also counts temporary files a kill left behind in the folder, then sweeps them with remove_stale_temporaries.
# Usage: pwsh -File kill_test.ps1 -Exe <kill_writer.exe> [-Trials 200] [-Dir <folder>] [-Seed 20261006]
param(
    [Parameter(Mandatory = $true)][string]$Exe,
    [int]$Trials = 200,
    [string]$Dir = "$env:TEMP\simple_file_kill",
    [int]$Seed = 20261006
)
if (Test-Path $Dir) { Remove-Item -Recurse -Force $Dir -Confirm:$false }
New-Item -ItemType Directory -Force $Dir | Out-Null
$note = Join-Path $Dir "note.md"
$v0 = "VERSION 0`r`n" + ('x' * 4000) + "`r`nEND 0`r`n"
$re = '^VERSION (\d+)\r?\nx{4000}\r?\nEND \1\r?\n$'
$rng = [System.Random]::new($Seed)
$complete = 0; $empty = 0; $torn = 0; $missing = 0; $advanced = 0
for ($i = 1; $i -le $Trials; $i++) {
    [System.IO.File]::WriteAllText($note, $v0)
    $p = Start-Process -FilePath $Exe -ArgumentList @("`"$note`"") -PassThru -NoNewWindow -RedirectStandardError (Join-Path $Dir "err.txt")
    Start-Sleep -Milliseconds ($rng.Next(60, 400))
    Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
    $p.WaitForExit()
    if (-not (Test-Path -LiteralPath $note)) { $missing++; continue }
    $b = [System.IO.File]::ReadAllText($note)
    if ($b.Length -eq 0) { $empty++ }
    elseif ($b -match $re) { $complete++; if ([int]$Matches[1] -gt 0) { $advanced++ } }
    else { $torn++ }
}
$tmpLeft = @(Get-ChildItem -LiteralPath $Dir -Force -Filter '.~sf*.tmp').Count
$errLines = 0
if (Test-Path (Join-Path $Dir "err.txt")) { $errLines = @(Get-Content (Join-Path $Dir "err.txt")).Count }
"exe=$Exe"
"trials=$Trials complete=$complete (of which advanced past v0: $advanced) empty=$empty torn=$torn missing=$missing tmp_left=$tmpLeft last_trial_stderr_lines=$errLines"
& $Exe sweep $Dir
$tmpAfter = @(Get-ChildItem -LiteralPath $Dir -Force -Filter '.~sf*.tmp').Count
"tmp_left after remove_stale_temporaries: $tmpAfter"
