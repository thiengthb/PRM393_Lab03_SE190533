# Attendo dev loop for one client (Windows PowerShell 5).
#
# Does exactly three things, nothing else:
#   1. keeps ~/develop/attendo on the latest commit of one branch (git fetch every few seconds),
#   2. runs one client with `flutter run`,
#   3. hot-reloads it when .dart files change, and restarts it when pubspec.yaml changes.
#
#   dev.ps1 -Target phone     lecturer app on the USB phone
#   dev.ps1 -Target windows   lecturer app as a Windows window (release build: the Firebase C++
#                             SDK ships no Debug libs for App Check, so no hot reload; it
#                             rebuilds itself when code changes, about a minute)
#   dev.ps1 -Target lecturer  lecturer app in the browser on http://localhost:7303 (same desktop
#                             layout as Windows when the window is wider than 900 px, hot reload)
#   dev.ps1 -Target admin     web admin on http://localhost:7301
#   dev.ps1 -Target student   student web on http://localhost:7302
#
# Close the window to stop. Log: ~/develop/.attendo-dev/run-<target>.log
# Optional key file ~/develop/.attendo-dev/key-<target>, one action per line:
#   r | R                     hot reload | hot restart
#   shot                      (phone) screenshot to ~/develop/.attendo-dev/phone.png
#   tap X Y | swipe X1 Y1 X2 Y2 MS | key back|home|enter | text WORD   (phone, via adb input;
#                             WORD is letters, digits and @._- only)
# Nothing else is accepted: the file cannot run commands.
param(
  [ValidateSet('phone', 'windows', 'lecturer', 'admin', 'student')] [string]$Target = 'phone',
  [string]$Branch = 'claude/attendo-dev',
  [string]$Repo = "$env:USERPROFILE\develop\attendo"
)

$Dev = "$env:USERPROFILE\develop\.attendo-dev"
$Log = "$Dev\run-$Target.log"
$Key = "$Dev\key-$Target"
New-Item -ItemType Directory -Force $Dev | Out-Null
$Host.UI.RawUI.WindowTitle = "Attendo dev: $Target ($Branch) - dong cua so de dung"

$tools = @(
  "$env:USERPROFILE\develop\flutter\bin",
  "$env:LOCALAPPDATA\Microsoft\WinGet\Links",
  "$env:LOCALAPPDATA\Programs\platform-tools",
  "$env:USERPROFILE\.local\share\platform-tools",
  "$env:LOCALAPPDATA\Android\Sdk\platform-tools"
) | Where-Object { Test-Path $_ }
$env:PATH = (($tools + @($env:PATH)) -join ';')

# One sync at a time across the dev windows that share the working copy.
$mutex = New-Object System.Threading.Mutex($false, 'AttendoDevSync')
function Sync-Repo {
  try { if (-not $mutex.WaitOne(10000)) { return $false } }
  catch [System.Threading.AbandonedMutexException] { }  # a closed window left it; we own it now
  try {
    if (-not (Test-Path "$Repo\.git")) {
      git clone --branch $Branch https://github.com/thiengthb/PRM393_Lab03_SE190533 $Repo 2>&1 | Out-Host
    }
    $before = (git -C $Repo rev-parse HEAD).Trim()
    # Four dev windows share this working copy: one fetch every 10 s is enough for all of
    # them (each fetching every 4 s kept the lock busy and starved the phone window's actions).
    $stampFile = "$Dev\last-fetch.txt"
    $fresh = (Test-Path $stampFile) -and ((Get-Date) - (Get-Item $stampFile).LastWriteTime).TotalSeconds -lt 10
    # Another window fetched and reset the shared copy moments ago; Get-Stamp sees changed files.
    if ($fresh) { return $false }
    Set-Content -Path $stampFile -Value (Get-Date -Format o)
    # A stalled fetch (network, or a credential prompt) must not freeze the window: time limit.
    $env:GIT_TERMINAL_PROMPT = '0'
    $f = Start-Process -FilePath 'git' -ArgumentList @('-C', $Repo, 'fetch', '--quiet', 'origin', $Branch) `
      -NoNewWindow -PassThru -RedirectStandardOutput "$Dev\git-out-$Target.txt" -RedirectStandardError "$Dev\git-err-$Target.txt"
    if (-not $f.WaitForExit(30000)) { try { $f.Kill() } catch {}; Write-Host "$(Get-Date -Format HH:mm:ss) git fetch qua 30 giay, bo qua"; return $false }
    $after = (git -C $Repo rev-parse FETCH_HEAD).Trim()
    if ($after -and $after -ne $before) {
      $changed = git -C $Repo diff --name-only $before $after
      git -C $Repo reset --quiet --hard $after
      Write-Host "$(Get-Date -Format HH:mm:ss) code moi $($after.Substring(0,7))"
      # Native or package changes need a full rebuild, not a hot reload.
      return ($changed | Where-Object { $_ -like '*pubspec.yaml' -or $_ -like 'mobile/android/*' -or $_ -like 'mobile/windows/*' -or $_ -like '*/web/index.html' }).Count -gt 0
    }
    return $false
  } finally { $mutex.ReleaseMutex() }
}

function Get-Stamp {
  $dirs = @("$Repo\mobile\lib", "$Repo\packages\core\lib", "$Repo\web\lib") | Where-Object { Test-Path $_ }
  $files = Get-ChildItem -Path $dirs -Recurse -Filter '*.dart' -ErrorAction SilentlyContinue
  $max = ($files | ForEach-Object { $_.LastWriteTimeUtc.Ticks } | Measure-Object -Maximum).Maximum
  return "$max/$($files.Count)"
}

function Start-Client {
  switch ($Target) {
    'phone' {
      # Start the adb server on its own first (see Invoke-Adb), so the piped call below cannot hang.
      $sv = Start-Process -FilePath 'adb' -ArgumentList 'start-server' -NoNewWindow -PassThru `
        -RedirectStandardOutput "$Dev\adb-out.txt" -RedirectStandardError "$Dev\adb-err.txt"
      [void]$sv.WaitForExit(15000)
      $line = adb devices | Select-String "`tdevice$" | Select-Object -First 1
      if (-not $line) { Write-Host 'Khong thay dien thoai: cam cap USB, bat Go loi USB, bam Cho phep tren dien thoai.'; return $null }
      $script:Serial = $line.ToString().Split("`t")[0]
      $dir = "$Repo\mobile"; $cmd = "run -d $script:Serial"
      # Decision 004: App Check debug token for AI Logic, kept outside the repo.
      $tokenFile = "$env:USERPROFILE\develop\attendo-config\app-check-debug-token.txt"
      if (Test-Path $tokenFile) {
        $tok = (Get-Content $tokenFile -Raw).Trim()
        if ($tok -match '^[A-Za-z0-9-]{20,64}$') { $cmd += " --dart-define=APP_CHECK_DEBUG_TOKEN=$tok" }
      }
    }
    'windows' {
      # A still-open attendo.exe locks the files the build installs (MSB3073 at INSTALL).
      Get-Process -Name 'attendo' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
      $dir = "$Repo\mobile"; $cmd = 'run -d windows --release'
    }
    'lecturer' { $dir = "$Repo\mobile"; $cmd = 'run -d web-server --web-hostname localhost --web-port 7303 --dart-define=PORTAL=lecturer' }
    'admin' { $dir = "$Repo\web"; $cmd = 'run -d web-server --web-hostname localhost --web-port 7301' }
    'student' { $dir = "$Repo\mobile"; $cmd = 'run -d web-server --web-hostname localhost --web-port 7302 --dart-define=PORTAL=student' }
  }
  foreach ($pkg in @("$Repo\packages\core", $dir)) { Push-Location $pkg; flutter pub get *> $null; Pop-Location }
  $psi = New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName = 'cmd.exe'
  $psi.Arguments = "/c flutter $cmd > `"$Log`" 2>&1"
  $psi.WorkingDirectory = $dir
  $psi.UseShellExecute = $false
  $psi.RedirectStandardInput = $true
  Write-Host "$(Get-Date -Format HH:mm:ss) flutter $($cmd -replace 'APP_CHECK_DEBUG_TOKEN=\S+', 'APP_CHECK_DEBUG_TOKEN=***')"
  return [System.Diagnostics.Process]::Start($psi)
}

# adb may start its background server on any call; that server inherits a piped stdout and
# PowerShell then waits forever for the pipe to close. Run each adb call as its own process
# with files for output and a time limit, so one stuck call never freezes this window.
function Invoke-Adb([string[]]$AdbArgs) {
  $all = @('-s', $script:Serial) + $AdbArgs
  $pr = Start-Process -FilePath 'adb' -ArgumentList $all -NoNewWindow -PassThru `
    -RedirectStandardOutput "$Dev\adb-out.txt" -RedirectStandardError "$Dev\adb-err.txt"
  if (-not $pr.WaitForExit(15000)) {
    try { $pr.Kill() } catch {}
    Write-Host "$(Get-Date -Format HH:mm:ss) adb qua 15 giay, bo qua: $($AdbArgs -join ' ')"
  }
}

function Invoke-Key([string]$k) {
  $stamp = Get-Date -Format HH:mm:ss
  if ($k -ceq 'r' -or $k -ceq 'R') { $p.StandardInput.Write($k); Write-Host "$stamp phim $k"; return }
  if ($Target -ne 'phone' -or -not $script:Serial) { return }
  if ($k -eq 'shot') {
    Invoke-Adb @('shell', 'screencap', '-p', '/sdcard/attendo-dev.png')
    Invoke-Adb @('pull', '/sdcard/attendo-dev.png', "$Dev\phone.png")
    Write-Host "$stamp chup man dien thoai"
  } elseif ($k -match '^tap (\d{1,4}) (\d{1,4})$') {
    Invoke-Adb @('shell', 'input', 'tap', $Matches[1], $Matches[2]); Write-Host "$stamp cham $($Matches[1]),$($Matches[2])"
  } elseif ($k -match '^swipe (\d{1,4}) (\d{1,4}) (\d{1,4}) (\d{1,4}) (\d{1,4})$') {
    Invoke-Adb @('shell', 'input', 'swipe', $Matches[1], $Matches[2], $Matches[3], $Matches[4], $Matches[5]); Write-Host "$stamp vuot"
  } elseif ($k -match '^key (back|home|enter)$') {
    $code = @{ back = 4; home = 3; enter = 66 }[$Matches[1]]
    Invoke-Adb @('shell', 'input', 'keyevent', "$code"); Write-Host "$stamp phim $($Matches[1])"
  } elseif ($k -match '^text ([A-Za-z0-9@._-]{1,64})$') {
    Invoke-Adb @('shell', 'input', 'text', $Matches[1]); Write-Host "$stamp go chu"
  } elseif ($k -match '^wait (\d{1,2})$') {
    Start-Sleep -Seconds ([int]$Matches[1])
  }
}

[void](Sync-Repo)
$p = Start-Client
$last = Get-Stamp
$tick = 0
function Beat([string]$stage) { try { Set-Content -Path "$Dev\beat-$Target.txt" -Value "$(Get-Date -Format HH:mm:ss) $stage" } catch {} }
while ($true) {
  Beat 'cho'
  Start-Sleep -Milliseconds 800
  if ($null -eq $p -or $p.HasExited) {
    Write-Host 'flutter da dung. Thu lai sau 10 giay (dong cua so de thoi).'
    Start-Sleep -Seconds 10; $p = Start-Client; continue
  }
  Beat 'lenh'
  if (Test-Path $Key) {
    $lines = Get-Content $Key; Remove-Item $Key -Force
    foreach ($k in $lines) {
      Beat "lenh: $($k.Trim())"
      try { Invoke-Key $k.Trim() } catch { Write-Host "$(Get-Date -Format HH:mm:ss) loi lenh '$k': $_" }
    }
  }
  Beat 'dong bo'
  if ((++$tick % 5) -eq 0 -and (Sync-Repo)) {
    Write-Host 'pubspec hoac ma native doi: dung lai app'; $p.StandardInput.Write('q'); $p.WaitForExit(15000) | Out-Null
    $p = Start-Client; $last = Get-Stamp; continue
  }
  Beat 'quet code'
  $now = Get-Stamp
  if ($now -ne $last) {
    Start-Sleep -Milliseconds 600
    $last = Get-Stamp
    if ($Target -eq 'windows') {
      # Release build: no hot reload, quit and build again.
      Write-Host "$(Get-Date -Format HH:mm:ss) code doi, dung lai ban Windows"
      $p.StandardInput.Write('q'); $p.WaitForExit(20000) | Out-Null
      $p = Start-Client
    } else {
      # Web has no stateful hot reload; a restart keeps the URL and reloads the page.
      # Not $key: PowerShell names are case-insensitive, $key would overwrite $Key (the action file
      # path) and the window would stop reading actions after the first reload.
      $reloadKey = if ($Target -in @('lecturer', 'admin', 'student')) { 'R' } else { 'r' }
      Beat "nap lai $reloadKey"
      $p.StandardInput.Write($reloadKey)
      Write-Host "$(Get-Date -Format HH:mm:ss) nap lai ($reloadKey)"
    }
  }
}
