# ============================================================
#  push-to-github.ps1 — docs/ の中身を GitHub へ送る
#
#  初回:
#    .\push-to-github.ps1 -Url https://github.com/あなた/リポジトリ名.git
#  2回目以降:
#    .\push-to-github.ps1
#
#  -Message "..."  … コミットの説明（省略すると版から自動で作る）
#  -DryRun         … 何をするか出すだけ
# ============================================================
[CmdletBinding()]
param(
  [string]$Url,
  [string]$Message,
  [switch]$DryRun
)
$ErrorActionPreference = 'Stop'
$here = $PSScriptRoot
$docs = Join-Path $here 'docs'

function Say($s) { Write-Host $s }
function Die($s) { throw $s }

# ---- git があるか ----
$git = (Get-Command git -ErrorAction SilentlyContinue)
if (-not $git) { Die 'git が見つかりません。https://git-scm.com/ から入れてください。' }

# ---- 置くものが揃っているか ----
if (-not (Test-Path (Join-Path $docs 'manifest.json'))) {
  Die "docs\manifest.json がありません。先に release.ps1 を実行してください。"
}
if (-not (Test-Path (Join-Path $docs 'VALOTRACK-Setup.exe'))) {
  Die "docs\VALOTRACK-Setup.exe がありません。先に release.ps1 を実行してください。"
}

$mf = (Get-Content (Join-Path $docs 'manifest.json') -Raw -Encoding UTF8) | ConvertFrom-Json
$ver = $mf.version
Say ""
Say "  版      : $ver"
Say "  入手先  : $($mf.url)"

# ---- 名前とメールが未設定なら、このリポジトリだけに設定する ----
Push-Location $here
try {
  # git のコマンドは、未初期化だと 0 以外を返す。落とさずに拾う。
  function Git-Try {
    $old = $ErrorActionPreference
    $ErrorActionPreference = 'SilentlyContinue'
    try { $out = (& git @args 2>$null); if ($LASTEXITCODE -ne 0) { return '' }; return ($out | Out-String).Trim() }
    catch { return '' }
    finally { $ErrorActionPreference = $old }
  }

  $hasGit = Test-Path (Join-Path $here '.git')
  if (-not $hasGit) {
    Say "  git を初期化します"
    if (-not $DryRun) { & git init -b main | Out-Null; $hasGit = $true }
  }

  if ($hasGit -and -not $DryRun) {
    if (-not (Git-Try config user.name)) {
      & git config user.name 'VALOTRACK' | Out-Null
      Say "  user.name を VALOTRACK に設定（このリポジトリだけ）"
    }
    if (-not (Git-Try config user.email)) {
      & git config user.email 'valotrack@localhost' | Out-Null
      Say "  user.email を設定（このリポジトリだけ）"
    }
  }

  # ---- 送り先 ----
  $remote = if ($hasGit) { Git-Try remote get-url origin } else { '' }
  if ($Url) {
    if ($Url -notmatch '^https://github\.com/.+\.git$' -and $Url -notmatch '^git@github\.com:.+\.git$') {
      Die "送り先の形が違います。例: https://github.com/あなた/リポジトリ名.git"
    }
    if (-not $DryRun) {
      if ($remote) { & git remote set-url origin $Url | Out-Null }
      else { & git remote add origin $Url | Out-Null }
    }
    $remote = $Url
  }
  if (-not $remote) {
    Die "送り先がまだ決まっていません。最初の1回だけ -Url https://github.com/あなた/リポジトリ名.git を付けてください。"
  }
  Say "  送り先  : $remote"
  Say ""

  if ($DryRun) { Say '（-DryRun なので、ここまでで終わります）'; return }

  if (-not $Message) { $Message = "VALOTRACK $ver" }

  & git add -A
  $changed = (& git status --porcelain)
  if (-not $changed) {
    Say '変わっているものがありません。送るものはありません。'
    return
  }
  & git commit -m $Message | Out-Null
  Say "コミット: $Message"

  Say '送信中...'
  & git push -u origin main
  if ($LASTEXITCODE -ne 0) {
    Say ''
    Say '送信に失敗しました。よくある原因:'
    Say '  ・リポジトリがまだ空でない（README を作ってしまった等）'
    Say '      → git pull --rebase origin main のあと、もう一度実行'
    Say '  ・ログインを求められた'
    Say '      → ブラウザが開いたら GitHub にログインしてください'
    Die '送信できませんでした'
  }

  # ---- 公開URLを推測して出す ----
  $m = [regex]::Match($remote, 'github\.com[:/]([^/]+)/([^/]+?)(\.git)?$')
  if ($m.Success) {
    $user = $m.Groups[1].Value; $rep = $m.Groups[2].Value
    Say ''
    Say '送信できました。'
    Say ''
    Say '  Settings → Pages で次のように設定してください:'
    Say '    Source: Deploy from a branch'
    Say '    Branch: main  /  フォルダ: /docs'
    Say ''
    Say '  1〜2分後、ここが見えるようになります:'
    Say "    https://$user.github.io/$rep/manifest.json"
    Say ''
    Say '  そのURLを VALOTRACK に教えるには:'
    Say "    powershell -File ..\valotrack\app\release.ps1 -UpdateUrl https://$user.github.io/$rep/manifest.json -Bump minor"
  }
}
finally { Pop-Location }
