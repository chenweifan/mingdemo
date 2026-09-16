# 在带有本地加速代理的环境下可靠推送 GitHub
#
# 背景：Watt Toolkit（Steam++）等加速器会把 github.com 等域名写进 hosts 指向
#       127.0.0.1，并在本地 443 端口做 TLS 中间人反代。这种链路上有四类常见失败：
#         1) 中间人证书的吊销列表不可达 -> schannel CRYPT_E_NO_REVOCATION_CHECK
#         2) 加速器只支持 HTTP/1.1    -> HTTP/2 复用中断
#         3) 凭据缺失时弹出 GUI 登录框 -> 自动化场景永久挂起
#         4) 链路停滞                 -> 传输无限等待，看起来像“卡死”
#       本脚本把上述风险逐条关掉，并在彻底失败时自动产出 git bundle 兜底。
#
# 用法：
#   pwsh -File tools/push-github.ps1                # 推送当前分支到 origin
#   pwsh -File tools/push-github.ps1 -Branch main   # 指定分支
#   pwsh -File tools/push-github.ps1 -NoBundle      # 失败时不生成 bundle
#
# 注意：必须在能访问网络的普通终端运行；若在受限沙箱中运行，会以
#       schannel SEC_E_NO_CREDENTIALS 失败（进程无法访问证书存储与网络）。

[CmdletBinding()]
param(
  [string]$Remote = 'origin',
  [string]$Branch,
  [switch]$NoBundle
)

$ErrorActionPreference = 'Stop'

function Say([string]$msg, [string]$tone) {
  $prefix = '[push] '
  switch ($tone) {
    'ok'   { Write-Host ($prefix + $msg) -ForegroundColor Green }
    'warn' { Write-Host ($prefix + $msg) -ForegroundColor Yellow }
    'err'  { Write-Host ($prefix + $msg) -ForegroundColor Red }
    default { Write-Host ($prefix + $msg) }
  }
}

# ---------------------------------------------------------------- 0. 定位仓库
$root = (git rev-parse --show-toplevel 2>$null)
if (-not $root) { Say '当前目录不是 git 仓库' 'err'; exit 2 }
Set-Location $root
if (-not $Branch) { $Branch = (git rev-parse --abbrev-ref HEAD).Trim() }
$remoteUrl = (git remote get-url $Remote 2>$null)
if (-not $remoteUrl) { Say "远端 $Remote 不存在" 'err'; exit 2 }
Say "仓库 $root / 分支 $Branch / 远端 $remoteUrl"

# ------------------------------------------------------- 1. 环境探测（只读诊断）
try {
  $listener = Get-NetTCPConnection -LocalPort 443 -State Listen -ErrorAction Stop |
              Select-Object -First 1
  if ($listener) {
    $proc = Get-Process -Id $listener.OwningProcess -ErrorAction SilentlyContinue
    if ($proc -and $proc.ProcessName -notmatch 'System|http|svchost') {
      Say "检测到本地 443 监听：$($proc.ProcessName)（很可能是加速代理）" 'warn'
    }
  }
} catch { }

$hostsHit = @()
try {
  $hostsHit = Get-Content "$env:SystemRoot\System32\drivers\etc\hosts" -ErrorAction Stop |
              Where-Object { $_ -match '^\s*127\.0\.0\.1\s+.*github' }
} catch { }
if ($hostsHit.Count -gt 0) {
  Say "hosts 中有 $($hostsHit.Count) 条 github 域名指向 127.0.0.1（加速器接管）" 'warn'
}

# ------------------------------------------------- 2. 穿透加速代理的通用参数
#    - http.version=HTTP/1.1        加速器普遍不支持 h2 复用
#    - schannelCheckRevoke=false    中间人证书吊销列表不可达（Git for Windows 默认已是 false，此处显式固定）
#    - lowSpeedLimit/Time           链路停滞时果断失败，而不是无限等待
#    - credential.interactive=false 禁止弹出凭据 GUI，缺失凭据直接报错
$GIT_ARGS = @(
  '-c', 'http.version=HTTP/1.1',
  '-c', 'http.schannelCheckRevoke=false',
  '-c', 'http.lowSpeedLimit=1000',
  '-c', 'http.lowSpeedTime=60',
  '-c', 'credential.interactive=false'
)
$env:GIT_TERMINAL_PROMPT = '0'   # 禁止终端交互式询问
$env:GCM_INTERACTIVE     = 'never'

# ------------------------------------------------------------- 3. 连通性预检
Say '连通性预检…'
$sw = [System.Diagnostics.Stopwatch]::StartNew()
$probe = (git @GIT_ARGS ls-remote --heads $Remote 2>&1)
$probeOk = ($LASTEXITCODE -eq 0)
$sw.Stop()

if (-not $probeOk) {
  $text = ($probe | Out-String)
  Say "预检失败（$($sw.ElapsedMilliseconds) ms）" 'err'
  if ($text -match 'SEC_E_NO_CREDENTIALS') {
    Say '原因：进程无法访问证书存储/网络 —— 通常是运行在受限沙箱中，请在普通终端重试。' 'err'
  } elseif ($text -match 'CRYPT_E_NO_REVOCATION_CHECK') {
    Say '原因：证书吊销检查失败 —— 加速器中间人证书的吊销列表不可达。' 'err'
  } elseif ($text -match 'Authentication failed|401|403|terminal prompts disabled') {
    Say '原因：凭据无效或缺失 —— 请执行 git credential-manager github login 重新登录。' 'err'
  }
  $text.Trim() -split "`n" | Select-Object -First 4 | ForEach-Object { Say ('  ' + $_.Trim()) }
} else {
  Say "预检通过（$($sw.ElapsedMilliseconds) ms）" 'ok'
}

# ------------------------------------------------------------------ 4. 推送
$pushed = $false
if ($probeOk) {
  $localSha  = (git rev-parse HEAD).Trim()
  $remoteSha = (($probe | Select-String -Pattern "refs/heads/$Branch$") -split '\s+')[0]
  if ($remoteSha -eq $localSha) {
    Say "远端 $Branch 已是最新（$($localSha.Substring(0,7))），无需推送" 'ok'
    $pushed = $true
  } else {
    for ($attempt = 1; $attempt -le 2; $attempt++) {
      Say "推送第 $attempt 次尝试…"
      $t = [System.Diagnostics.Stopwatch]::StartNew()
      git @GIT_ARGS push $Remote "$Branch`:$Branch" 2>&1 | ForEach-Object { Say ('  ' + $_.ToString()) }
      $code = $LASTEXITCODE
      $t.Stop()
      if ($code -eq 0) { Say "推送成功（$($t.ElapsedMilliseconds) ms）" 'ok'; $pushed = $true; break }
      Say "第 $attempt 次失败，退出码 $code（$($t.ElapsedMilliseconds) ms）" 'warn'
      if ($attempt -eq 1) { Start-Sleep -Seconds 2 }
    }
  }
}

# ----------------------------------------------------- 5. 失败兜底：git bundle
if (-not $pushed -and -not $NoBundle) {
  $outDir = Join-Path $root 'dist-artifacts'
  if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }
  $name = Split-Path $root -Leaf
  $bundle = Join-Path $outDir "$name.bundle"
  Say '推送未成功，生成 git bundle 兜底…' 'warn'
  git bundle create $bundle --all 2>&1 | ForEach-Object { Say ('  ' + $_.ToString()) }
  if ($LASTEXITCODE -eq 0) {
    Say "已生成 $bundle（含完整历史）" 'ok'
    Say '可在网络正常的机器上执行：'
    Say "  git clone <bundle 路径> $name"
    Say "  cd $name && git remote set-url origin $remoteUrl && git push -u origin $Branch"
  }
}

# ------------------------------------------------------------------ 6. 摘要
$head = (git rev-parse --short HEAD).Trim()
Say "本地 HEAD：$head"
if ($pushed) { Say '结果：远端已同步 ✓' 'ok'; exit 0 } else { Say '结果：推送失败 ✗' 'err'; exit 1 }
