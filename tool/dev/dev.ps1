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
# Optional key file ~/develop/.attendo-dev/key-<target>: a single r (reload) or R (restart).
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
  [void]$mutex.WaitOne()
  try {
    if (-not (Test-Path "$Repo\.git")) {
      git clone --branch $Branch https://github.com/thiengthb/PRM393_Lab03_SE190533 $Repo 2>&1 | Out-Host
    }
    $before = (git -C $Repo rev-parse HEAD).Trim()
    git -C $Repo fetch --quiet origin $Branch 2>$null
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
      $line = adb devices | Select-String "`tdevice$" | Select-Object -First 1
      if (-not $line) { Write-Host 'Khong thay dien thoai: cam cap USB, bat Go loi USB, bam Cho phep tren dien thoai.'; return $null }
      $dir = "$Repo\mobile"; $cmd = "run -d $($line.ToString().Split("`t")[0])"
    }
    'windows' { $dir = "$Repo\mobile"; $cmd = 'run -d windows --release' }
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
  Write-Host "$(Get-Date -Format HH:mm:ss) flutter $cmd"
  return [System.Diagnostics.Process]::Start($psi)
}

[void](Sync-Repo)
$p = Start-Client
$last = Get-Stamp
$tick = 0
while ($true) {
  Start-Sleep -Milliseconds 800
  if ($null -eq $p -or $p.HasExited) {
    Write-Host 'flutter da dung. Thu lai sau 10 giay (dong cua so de thoi).'
    Start-Sleep -Seconds 10; $p = Start-Client; continue
  }
  if ((++$tick % 5) -eq 0 -and (Sync-Repo)) {
    Write-Host 'pubspec hoac ma native doi: dung lai app'; $p.StandardInput.Write('q'); $p.WaitForExit(15000) | Out-Null
    $p = Start-Client; $last = Get-Stamp; continue
  }
  if (Test-Path $Key) {
    $k = (Get-Content $Key -Raw).Trim(); Remove-Item $Key -Force
    if ($k -ceq 'r' -or $k -ceq 'R') { $p.StandardInput.Write($k); Write-Host "$(Get-Date -Format HH:mm:ss) phim $k" }
  }
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
      $key = if ($Target -in @('lecturer', 'admin', 'student')) { 'R' } else { 'r' }
      $p.StandardInput.Write($key)
      Write-Host "$(Get-Date -Format HH:mm:ss) nap lai ($key)"
    }
  }
}
