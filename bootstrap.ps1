# 로또 프로젝트 새 Windows PC 한 줄 설치 (비밀 정보 없음, 공개 파일)
#   irm https://raw.githubusercontent.com/kysmk1987-lgtm/lotto-data/main/bootstrap.ps1 | iex
# 점검만(아무것도 설치/변경하지 않음):
#   $env:LOTTO_BOOTSTRAP_CHECK = "1"; irm https://raw.githubusercontent.com/kysmk1987-lgtm/lotto-data/main/bootstrap.ps1 | iex
# setup-dev.ps1 에 옵션 전달: $env:LOTTO_SETUP_ARGS = "-SkipAndroid -SkipVercel"
# 하는 일: Git·GitHub CLI 설치 → GitHub 로그인 → lotto/lotto-app 클론(있으면 pull) → lotto\scripts\setup-dev.ps1 → Cursor 로 워크스페이스 열기
& {
    $ErrorActionPreference = "Stop"
    try { [Console]::OutputEncoding = [Text.Encoding]::UTF8 } catch {}
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

    $CheckOnly = ($env:LOTTO_BOOTSTRAP_CHECK -eq "1")
    $Owner = "kysmk1987-lgtm"
    $Root = Join-Path $env:USERPROFILE "Documents\GitHub"
    if ($env:LOTTO_ROOT) { $Root = $env:LOTTO_ROOT }

    function Step([string]$m) { Write-Host ""; Write-Host "==> $m" -ForegroundColor Cyan }
    function Ok([string]$m) { Write-Host "  [OK]   $m" -ForegroundColor Green }
    function Todo([string]$m) { Write-Host "  [필요] $m" -ForegroundColor Yellow }
    function Update-SessionPath {
        $env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [Environment]::GetEnvironmentVariable("Path", "User")
        foreach ($d in @("$env:ProgramFiles\Git\cmd", "$env:ProgramFiles\GitHub CLI", "$env:LOCALAPPDATA\Programs\cursor\resources\app\bin")) {
            if ((Test-Path $d) -and (($env:Path -split ";") -notcontains $d)) { $env:Path += ";$d" }
        }
        foreach ($n in @("JAVA_HOME", "ANDROID_HOME", "ANDROID_SDK_ROOT")) {
            $v = [Environment]::GetEnvironmentVariable($n, "User")
            if ($v) { Set-Item "env:$n" $v }
        }
    }
    function Has([string]$exe) { [bool](Get-Command $exe -ErrorAction SilentlyContinue) }
    function Run([string]$exe, [string[]]$a) {
        & $exe @a | Out-Host
        if ($LASTEXITCODE -ne 0) { throw "명령 실패 (exit $LASTEXITCODE): $exe $($a -join ' ')" }
    }

    Write-Host "로또 프로젝트 새 PC 설정 $(if ($CheckOnly) { '(점검 모드: 설치하지 않음)' })" -ForegroundColor White
    Write-Host "저장소 위치: $Root"
    Update-SessionPath

    try {
        Step "Git, GitHub CLI"
        foreach ($t in @(@{ Exe = "git"; Id = "Git.Git"; Name = "Git" }, @{ Exe = "gh"; Id = "GitHub.cli"; Name = "GitHub CLI" })) {
            if (Has $t.Exe) { Ok "$($t.Name) 있음"; continue }
            if ($CheckOnly) { Todo "$($t.Name) 설치 필요 (winget $($t.Id))"; continue }
            if (-not (Has "winget")) { throw "winget 이 없습니다. Microsoft Store 에서 '앱 설치 관리자'를 설치/업데이트한 뒤 다시 실행하세요." }
            Write-Host "  $($t.Name) 설치 중... (UAC 창이 뜨면 '예')"
            & winget install --id $t.Id -e --silent --accept-package-agreements --accept-source-agreements | Out-Host
            Update-SessionPath
            if (-not (Has $t.Exe)) { throw "$($t.Name) 설치 후에도 찾을 수 없습니다. PowerShell 을 새로 열고 다시 실행하세요." }
            Ok "$($t.Name) 설치됨"
        }

        Step "GitHub 로그인"
        $authed = $false
        if (Has "gh") {
            $prev = $ErrorActionPreference; $ErrorActionPreference = "Continue"
            & gh auth status --hostname github.com *> $null
            $authed = ($LASTEXITCODE -eq 0)
            $ErrorActionPreference = $prev
        }
        if ($authed) { Ok "gh 로그인됨" }
        elseif ($CheckOnly) { Todo "gh auth login 필요" }
        else {
            Write-Host "  표시되는 코드를 복사한 뒤 Enter → 브라우저에서 $Owner 계정으로 승인하세요."
            Run "gh" @("auth", "login", "--web", "-h", "github.com", "-p", "https")
            Ok "gh 로그인 완료"
        }
        if (-not $CheckOnly -and (Has "gh")) { Run "gh" @("auth", "setup-git") }

        Step "저장소 (lotto, lotto-app)"
        if (-not $CheckOnly) { New-Item -ItemType Directory -Force $Root | Out-Null }
        foreach ($name in @("lotto", "lotto-app")) {
            $dir = Join-Path $Root $name
            if (Test-Path (Join-Path $dir ".git")) {
                if ($CheckOnly) { Ok "$name 있음: $dir" }
                else { Run "git" @("-C", $dir, "pull", "--rebase", "--autostash"); Ok "$name 최신화" }
            } elseif ($CheckOnly) { Todo "$name 클론 필요 → $dir" }
            else { Run "gh" @("repo", "clone", "$Owner/$name", $dir); Ok "$name 클론 완료" }
        }

        $setup = Join-Path $Root "lotto\scripts\setup-dev.ps1"
        Step "개발 도구 설치/점검 (setup-dev.ps1)"
        if (Test-Path $setup) {
            $extra = @()
            if ($env:LOTTO_SETUP_ARGS) { $extra = @($env:LOTTO_SETUP_ARGS -split "\s+" | Where-Object { $_ }) }
            if ($CheckOnly) { $extra += "-CheckOnly" }
            & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $setup -Root $Root @extra
            if ($LASTEXITCODE -ne 0) { Todo "setup-dev.ps1 에서 일부 실패 (위 로그 확인 후 다시 실행해도 안전합니다)" }
        } else { Todo "setup-dev.ps1 없음 (lotto 클론 후 다시 실행)" }

        Step "Cursor 로 워크스페이스 열기"
        Update-SessionPath
        $ws = Join-Path $Root "lotto\lotto.code-workspace"
        $cursorExe = Join-Path $env:LOCALAPPDATA "Programs\cursor\Cursor.exe"
        if (-not (Test-Path $ws)) { Todo "워크스페이스 파일 없음: $ws" }
        elseif ($CheckOnly) {
            if (Has "cursor") { Ok "열기 명령: cursor `"$ws`"" }
            elseif (Test-Path $cursorExe) { Ok "열기 명령: $cursorExe `"$ws`"" }
            else { Todo "Cursor 미설치 (https://cursor.com 에서 설치)" }
        }
        elseif (Has "cursor") { & cursor $ws; Ok "Cursor 에서 여는 중: $ws" }
        elseif (Test-Path $cursorExe) { Start-Process $cursorExe -ArgumentList "`"$ws`""; Ok "Cursor 에서 여는 중: $ws" }
        else { Todo "Cursor 가 없습니다. https://cursor.com 에서 설치 후 이 파일을 여세요: $ws"; Start-Process $ws -ErrorAction SilentlyContinue }

        Write-Host ""
        Write-Host "완료. Cursor 가 이미 켜져 있었다면 완전히 종료 후 다시 열어야 새 PATH/JAVA_HOME 이 적용됩니다." -ForegroundColor White
        Write-Host "새 채팅에서: 'AGENTS.md 와 docs/HANDOFF.md 읽고 이어서 진행해줘'"
    } catch {
        Write-Host "  [실패] $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "  문제를 해결한 뒤 같은 명령을 다시 실행하면 이어서 진행합니다."
    }
}
