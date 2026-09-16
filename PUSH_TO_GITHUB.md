# 推送到 GitHub：本机加速链路适配指南

本机访问 GitHub 走的是**本地加速代理**，不是直连，也不是屏蔽。本文记录实测到的链路特征、
据此固定的 git 配置，以及推送失败时的排查与兜底路径。

---

## 1 · 实测环境（2026-09-16）

| 项 | 实测值 |
|---|---|
| 加速器 | **Watt Toolkit（Steam++）** —— `Steam++.Accelerator` 进程监听 `0.0.0.0:443` 与 `0.0.0.0:80` |
| 中间人根证书 | `CN=SteamTools Certificate, O=BeyondDimension, OU=Technical Department`（装在 `LocalMachine\Root`，2027-07-08 到期） |
| DNS 接管方式 | hosts 文件 **47 条**记录把加速域名指向 `127.0.0.1`：`github.com`、`api.github.com`、`raw.githubusercontent.com`、`objects.githubusercontent.com`、`github.io`、`huggingface.co`、`steampowered.com` 系列等 |
| 系统代理 | WinHTTP = Direct；WinINET `ProxyEnable=0` —— **没有配置代理**，走的是「hosts + 本地 443 反代」透明链路 |
| git | `2.55.0.windows.5`（libcurl 8.21.0 / Schannel），凭据助手 `manager`（GCM `2.9.1`） |
| 实测延迟 | `git ls-remote origin` **1159 ms** |
| TLS 行为 | `curl -k https://github.com` → `HTTP/1.1 200 OK`；**不带 `-k` 则失败**：`schannel: CRYPT_E_NO_REVOCATION_CHECK`（中间人证书的吊销列表不可达） |

> 关键结论：这条链路本身是**可用**的。失败几乎都来自「吊销检查 / HTTP 版本 / 凭据交互 / 链路停滞」四件事，
> 而不是网络不通。之前把它误判成「GitHub 被屏蔽」，是因为在受限沙箱中所有 TLS 出网都会以
> `schannel: SEC_E_NO_CREDENTIALS` 失败（进程无法访问证书存储），与加速器无关。

---

## 2 · 已固定的仓库级配置

已对本仓库执行（仅影响本仓库，未改全局）：

```bash
git config http.version HTTP/1.1            # 加速器普遍不支持 HTTP/2 复用
git config http.schannelCheckRevoke false   # 中间人证书吊销列表不可达；Git for Windows 默认已是 false，这里显式固定
git config http.lowSpeedLimit 1000          # 链路停滞时果断失败，避免无限等待
git config http.lowSpeedTime 60
```

查看当前生效值：

```bash
git config --local --list | Select-String 'http\.'
```

### 若要让本机所有仓库都受益

```bash
git config --global http.version HTTP/1.1
git config --global http.schannelCheckRevoke false
git config --global http.lowSpeedLimit 1000
git config --global http.lowSpeedTime 60
```

> `schannelCheckRevoke=false` 会跳过证书吊销校验。这是 Git for Windows 的出厂默认值，
> 也是加速器链路下的必要设置；若你在无中间人的网络环境中更看重严格校验，可只在本仓库开启。

---

## 3 · 推荐推送方式

```powershell
powershell -ExecutionPolicy Bypass -File tools/push-github.ps1              # 预检 → 推送 → 失败自动 bundle 兜底
powershell -ExecutionPolicy Bypass -File tools/push-github.ps1 -Branch main
powershell -ExecutionPolicy Bypass -File tools/push-github.ps1 -NoBundle    # 只推送，不生成 bundle
```

> 本机 **`pwsh` 不在 PATH 中**（子进程里 `pwsh` 无法解析），实际可用的是
> `C:\WINDOWS\System32\WindowsPowerShell\v1.0\powershell.exe`（PowerShell 5.1）。
> 若你装了 PowerShell 7，`pwsh -File tools/push-github.ps1` 同样可用——脚本对两者都兼容。

脚本做了四件事：

1. **只读探测**：识别本地 443 监听进程与 hosts 接管情况，先告诉你链路长什么样；
2. **连通性预检**：`git ls-remote` 并计时，失败时按错误码直接给出结论（沙箱 / 吊销检查 / 凭据）；
3. **带加固参数推送**：`http.version=HTTP/1.1`、`schannelCheckRevoke=false`、`lowSpeedLimit/Time`、
   `GIT_TERMINAL_PROMPT=0`、`credential.interactive=false`（禁止 GUI 弹窗）——即使仓库级配置被覆盖也依然生效；
   失败自动重试一次，并在推送前比对本地与远端 SHA，已同步则直接跳过；
4. **失败兜底**：在 `dist-artifacts/<repo>.bundle` 生成含完整历史的 bundle，并打印在正常网络下的推送命令。

实测输出示例：

```
[push] repo=C:/source/mingdemo branch=main remote=https://github.com/chenweifan/mingdemo.git
[push] port 443 is served by 'Steam++.Accelerator' (likely a local accelerator)
[push] hosts file redirects 27 github domains to 127.0.0.1 (accelerator in charge)
[push] probe OK (1422 ms)
[push] remote main is already at 68a139d - nothing to push
[push] result: remote is in sync
```

---

## 4 · 故障排查对照表

| 现象 / 报错 | 成因 | 处理 |
|---|---|---|
| `schannel: SEC_E_NO_CREDENTIALS`，**所有**域名都失败 | 运行在受限沙箱，进程无法访问证书存储与网络 | 在普通终端运行，或给 Agent 会话授予完整访问权限后重试 |
| `schannel: CRYPT_E_NO_REVOCATION_CHECK` | 加速器中间人证书的吊销列表不可达 | `git config http.schannelCheckRevoke false`（本仓库已设） |
| `curl` 能连、`git` 报 TLS 错 | 同上，curl 未禁用吊销检查 | 用 git 的配置项，而不是改 curl |
| 推送长时间无输出后失败 | h2 复用被中间人打断 | `git config http.version HTTP/1.1`（本仓库已设） |
| 命令卡住不动、桌面弹出登录框 | 凭据缺失触发 GCM 交互 | `GIT_TERMINAL_PROMPT=0` + `credential.interactive=false`（脚本已带） |
| `Authentication failed` / `403` | 存储的凭据过期或权限不足 | `git credential-manager github login`，或换成 PAT（需 `repo` 权限） |
| 大文件推送报 `HTTP 411` / RPC 失败 | 中间人对分块传输处理不佳 | `git config http.postBuffer 524288000` 后重试 |
| 换了网络仍失败 | 加速器未启动或规则未生效 | 启动 Watt Toolkit 并确认「GitHub 加速」已开启，`git ls-remote` 复测 |

---

## 5 · 备选通道

### 5.1 SSH over 443

`ssh.github.com` **不在** hosts 接管名单里，解析到真实 IP（实测 `20.205.243.160:443` 可连），
所以它是一条绕开本地反代的独立通道。当前机器 `%USERPROFILE%\.ssh` 目录不存在，尚未配置密钥。

```bash
ssh-keygen -t ed25519 -C "chen.weifan@qq.com"     # 生成密钥
# 把 ~/.ssh/id_ed25519.pub 内容添加到 https://github.com/settings/keys
# 然后在 ~/.ssh/config 写入：
#   Host github.com
#     HostName ssh.github.com
#     Port 443
#     User git
git remote set-url origin git@github.com:chenweifan/mingdemo.git
ssh -T git@github.com                             # 验证
```

### 5.2 bundle 转交

加速链路完全不可用时，用 `tools/push-github.ps1` 生成的 `dist-artifacts/mingdemo.bundle`
在任何网络正常的机器上还原并推送：

```bash
git clone mingdemo.bundle mingdemo
cd mingdemo
git remote set-url origin https://github.com/chenweifan/mingdemo.git
git push -u origin main
```

---

## 6 · 凭据说明

本机凭据由 **Git Credential Manager** 管理，Windows 凭据管理器中的条目标识为
`git:https://github.com`。推送时由 GCM 自动取出，全程无需交互。

```bash
git credential-manager github list      # 查看已登录账号
git credential-manager github logout    # 退出登录（凭据异常时使用）
git credential-manager github login     # 重新登录
```

> 请勿在终端或脚本中回显凭据内容；排障时只需确认「能否通过预检」即可。

---

## 7 · 编写该脚本时踩到的两个 PowerShell 坑

这两条与 GitHub 无关，但都会让「推送脚本」本身失败，记录下来避免重复踩。

### 7.1 PowerShell 5.1 会用 ANSI 编码读取无 BOM 的 .ps1

`tools/push-github.ps1` 的第一版带中文注释、以 UTF-8 无 BOM 保存，结果 PowerShell 5.1 按
系统 ANSI（GBK）解码源码，中文字节被误解码后**伪造出了引号字符**，解析器直接报出 10 处语法错误：

```
Unexpected token ')' in expression or statement. @ line 72
The string is missing the terminator: '. @ line 137
```

处理方式有两个，任选其一：

- **保持脚本为纯 ASCII**（当前做法）——任何代码页、任何 PowerShell 版本都能正确解析；
- 或存为 **UTF-8 with BOM**，PowerShell 5.1 见到 BOM 就会按 UTF-8 解码。

中文说明放在本文档（Markdown 始终按 UTF-8 读取）里，不放进脚本源码。

### 7.2 `$ErrorActionPreference='Stop'` 会把 git 的 stderr 升级成终止性错误

git 把推送进度（`To https://...`、`abc..def main -> main`）写到 **stderr**。在
`$ErrorActionPreference='Stop'` 下，PowerShell 把原生命令的 stderr 包装成 `NativeCommandError`
并当作终止性错误抛出，于是出现「**推送已经成功、脚本却报失败并以退出码 1 结束**」的假故障。

脚本用 `Invoke-Git` 包装函数解决：调用 git 期间临时切到 `Continue`，把 stderr 当作普通输出行收集，
再从 `$LASTEXITCODE` 读取真实退出码——既保留 cmdlet 的严格模式，又不会误判 git 的结果。

验证方式：连续执行两次脚本，第一次推送、第二次应识别为「已同步」并退出 0。

