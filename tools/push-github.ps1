# push-github.ps1 - reliably push to GitHub through a local TLS-intercepting accelerator
#
# WHY THIS EXISTS
#   Tools such as Watt Toolkit / Steam++ rewrite the hosts file so that github.com and
#   friends point at 127.0.0.1, then serve them from a local reverse proxy on port 443.
#   That path is usable, but four things break it:
#     1) the intercepting CA has no reachable revocation list -> schannel CRYPT_E_NO_REVOCATION_CHECK
#     2) the proxy usually speaks HTTP/1.1 only         -> HTTP/2 multiplexing stalls
#     3) a missing credential pops a GUI login window   -> automation hangs forever
#     4) a stalled link never times out                 -> looks like a freeze
#   This script disables all four risks and, if the push still fails, emits a git bundle
#   that can be carried to any machine with working network access.
#
# USAGE
#   powershell -ExecutionPolicy Bypass -File tools/push-github.ps1
#   powershell -ExecutionPolicy Bypass -File tools/push-github.ps1 -Branch main
#   powershell -ExecutionPolicy Bypass -File tools/push-github.ps1 -NoBundle
#   (pwsh 7 works too: pwsh -File tools/push-github.ps1)
#
# PORTABILITY NOTES - both are real traps hit while writing this script
#   1) This file is intentionally ASCII-only. Windows PowerShell 5.1 decodes a .ps1 file
#      that has no BOM using the ANSI code page, which turns UTF-8 comments into garbage
#      and can even fabricate quote characters that break parsing.
#   2) Native git commands write progress to stderr. With $ErrorActionPreference='Stop'
#      that stderr is promoted to a terminating error and aborts the script mid-push,
#      even though git succeeded. Invoke-Git below handles both concerns.
#
#   Run it from a normal terminal. Inside a confined sandbox every TLS connection fails
#   with "schannel: SEC_E_NO_CREDENTIALS" (no access to the certificate store / network),
#   which is unrelated to the accelerator.

[CmdletBinding()]
param(
  [string]$Remote = 'origin',
  [string]$Branch,
  [switch]$NoBundle
)

$ErrorActionPreference = 'Stop'

function Say {
  param([string]$Message, [string]$Tone)
  $prefix = '[push] '
  switch ($Tone) {
    'ok'    { Write-Host ($prefix + $Message) -ForegroundColor Green }
    'warn'  { Write-Host ($prefix + $Message) -ForegroundColor Yellow }
    'err'   { Write-Host ($prefix + $Message) -ForegroundColor Red }
    default { Write-Host ($prefix + $Message) }
  }
}

# Wrapper for native git calls: keeps 'Stop' semantics for cmdlets while treating git
# stderr as ordinary output, and records the real exit code in $script:GitExit.
$script:GitExit = 0
function Invoke-Git {
  param([string[]]$GitArgs)
  $previous = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  try {
    $lines = @(& git @GitArgs 2>&1 | ForEach-Object {
      if ($_ -is [System.Management.Automation.ErrorRecord]) { $_.Exception.Message }
      else { $_.ToString() }
    })
    $script:GitExit = $LASTEXITCODE
  } finally {
    $ErrorActionPreference = $previous
  }
  return ,$lines
}

# ---------------------------------------------------------------- 0. locate repo
$root = (Invoke-Git @('rev-parse', '--show-toplevel') | Select-Object -First 1)
if ($script:GitExit -ne 0 -or -not $root) { Say 'Not inside a git repository.' 'err'; exit 2 }
$root = $root.Trim()
Set-Location $root
if (-not $Branch) { $Branch = ((Invoke-Git @('rev-parse', '--abbrev-ref', 'HEAD')) | Select-Object -First 1).Trim() }
$remoteUrl = ((Invoke-Git @('remote', 'get-url', $Remote)) | Select-Object -First 1)
if ($script:GitExit -ne 0 -or -not $remoteUrl) { Say "Remote '$Remote' not found." 'err'; exit 2 }
$remoteUrl = $remoteUrl.Trim()
Say "repo=$root branch=$Branch remote=$remoteUrl"

# ------------------------------------------- 1. read-only environment detection
try {
  $listener = Get-NetTCPConnection -LocalPort 443 -State Listen -ErrorAction Stop |
              Select-Object -First 1
  if ($listener) {
    $proc = Get-Process -Id $listener.OwningProcess -ErrorAction SilentlyContinue
    if ($proc -and $proc.ProcessName -notmatch '^(System|svchost|http|nginx)$') {
      Say "port 443 is served by '$($proc.ProcessName)' (likely a local accelerator)" 'warn'
    }
  }
} catch { }

$hostsHit = @()
try {
  $hostsHit = @(Get-Content "$env:SystemRoot\System32\drivers\etc\hosts" -ErrorAction Stop |
                Where-Object { $_ -match '^\s*127\.0\.0\.1\s+.*github' })
} catch { }
if ($hostsHit.Count -gt 0) {
  Say "hosts file redirects $($hostsHit.Count) github domains to 127.0.0.1 (accelerator in charge)" 'warn'
}

# ---------------------------------- 2. hardening flags for the intercepting proxy
#   http.version=HTTP/1.1          proxies rarely support h2 multiplexing
#   schannelCheckRevoke=false      intercepting CA has no reachable revocation list
#                                  (Git for Windows already defaults to false; pinned here)
#   lowSpeedLimit/Time             fail fast on a stalled link instead of hanging
#   credential.interactive=false   never pop a credential GUI; fail with a clear message
$GIT_ARGS = @(
  '-c', 'http.version=HTTP/1.1',
  '-c', 'http.schannelCheckRevoke=false',
  '-c', 'http.lowSpeedLimit=1000',
  '-c', 'http.lowSpeedTime=60',
  '-c', 'credential.interactive=false'
)
$env:GIT_TERMINAL_PROMPT = '0'
$env:GCM_INTERACTIVE     = 'never'

# ---------------------------------------------------------- 3. connectivity probe
Say 'probing connectivity ...'
$sw = [System.Diagnostics.Stopwatch]::StartNew()
$probe = Invoke-Git ($GIT_ARGS + @('ls-remote', '--heads', $Remote))
$probeOk = ($script:GitExit -eq 0)
$sw.Stop()
$probeText = ($probe -join "`n")

if (-not $probeOk) {
  Say "probe FAILED ($($sw.ElapsedMilliseconds) ms)" 'err'
  if ($probeText -match 'SEC_E_NO_CREDENTIALS') {
    Say 'cause: no access to the certificate store / network - you are probably inside a' 'err'
    Say '       confined sandbox. Re-run from a normal terminal.' 'err'
  } elseif ($probeText -match 'CRYPT_E_NO_REVOCATION_CHECK') {
    Say 'cause: revocation check failed - the intercepting CA has no reachable CRL/OCSP.' 'err'
  } elseif ($probeText -match 'Authentication failed|401|403|terminal prompts disabled') {
    Say 'cause: credential invalid or missing - run: git credential-manager github login' 'err'
  }
  $probeText.Trim() -split "`n" | Select-Object -First 4 | ForEach-Object { Say ('  ' + $_.Trim()) }
} else {
  Say "probe OK ($($sw.ElapsedMilliseconds) ms)" 'ok'
}

# ---------------------------------------------------------------------- 4. push
$pushed = $false
if ($probeOk) {
  $localSha  = ((Invoke-Git @('rev-parse', 'HEAD')) | Select-Object -First 1).Trim()
  $remoteSha = ''
  $remoteLine = $probe |
    Where-Object { $_ -match ('refs/heads/' + [regex]::Escape($Branch) + '$') } |
    Select-Object -First 1
  if ($remoteLine) { $remoteSha = ($remoteLine -split '\s+')[0].Trim() }

  if ($remoteSha -eq $localSha) {
    Say "remote $Branch is already at $($localSha.Substring(0,7)) - nothing to push" 'ok'
    $pushed = $true
  } else {
    for ($attempt = 1; $attempt -le 2; $attempt++) {
      Say "push attempt $attempt ..."
      $t = [System.Diagnostics.Stopwatch]::StartNew()
      $pushOut = Invoke-Git ($GIT_ARGS + @('push', $Remote, ($Branch + ':' + $Branch)))
      $code = $script:GitExit
      $t.Stop()
      $pushOut | ForEach-Object { if ($_ -and $_.Trim()) { Say ('  ' + $_.Trim()) } }
      if ($code -eq 0) {
        Say "push OK ($($t.ElapsedMilliseconds) ms)" 'ok'
        $pushed = $true
        break
      }
      Say "attempt $attempt failed, exit=$code ($($t.ElapsedMilliseconds) ms)" 'warn'
      if ($attempt -eq 1) { Start-Sleep -Seconds 2 }
    }
  }
}

# --------------------------------------------------- 5. fallback: bundle on failure
if (-not $pushed -and -not $NoBundle) {
  $outDir = Join-Path $root 'dist-artifacts'
  if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }
  $name   = Split-Path $root -Leaf
  $bundle = Join-Path $outDir ($name + '.bundle')
  Say 'push failed - creating a git bundle fallback ...' 'warn'
  $bundleOut = Invoke-Git @('bundle', 'create', $bundle, '--all')
  $bundleOut | ForEach-Object { if ($_ -and $_.Trim()) { Say ('  ' + $_.Trim()) } }
  if ($script:GitExit -eq 0) {
    Say "bundle written: $bundle" 'ok'
    Say 'on a machine with working network access, run:'
    Say "  git clone <path-to-bundle> $name"
    Say "  cd $name"
    Say "  git remote set-url origin $remoteUrl"
    Say "  git push -u origin $Branch"
  }
}

# -------------------------------------------------------------------- 6. summary
$head = ((Invoke-Git @('rev-parse', '--short', 'HEAD')) | Select-Object -First 1).Trim()
Say "local HEAD: $head"
if ($pushed) { Say 'result: remote is in sync' 'ok'; exit 0 }
Say 'result: push FAILED' 'err'
exit 1
