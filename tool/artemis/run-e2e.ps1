# Runs the ARTEMIS E2E suite (e2e_test/) on the USB phone against the Firebase Emulator,
# 3 times per test by default, and writes evidence/artemis/results.md (Windows PowerShell 5).
#
#   run-e2e.ps1 -Step check      tools, ARTEMIS daemon, phone, Gemini key (prints nothing secret)
#   run-e2e.ps1 -Step lecturer   Lab 3 lecturer tests (TC-02..08, TC-11..16)
#   run-e2e.ps1 -Step student    Lab 3 student tests (TC-09, TC-10, TC-23)
#   run-e2e.ps1 -Step lab3       check + lecturer + student + report (default)
#   run-e2e.ps1 -Step report     rebuild evidence/artemis/results.md from e2e_test/runs/
#   run-e2e.ps1 -Step stop       stop the Firebase Emulator started by this script
#
# Before: ARTEMIS daemon running (develop\artemis\start.bat, http://127.0.0.1:8000) and the dev
# window for the phone closed (both install app.attendo on the same phone).
# Data: Auth + Firestore on the Emulator, reseeded before every test (QA_RESEED_CMD), so tests that
# close slots or approve requests can run again. TC-01 (Google on real Firebase) is skipped here.
# Log for Claude: ~/develop/.attendo-dev/artemis.log and artemis-*.log next to it.
param(
  [ValidateSet('check', 'lecturer', 'student', 'lab3', 'report', 'stop')] [string]$Step = 'lab3',
  [int]$Count = 3,
  [string]$Repo = "$env:USERPROFILE\develop\attendo",
  [string]$Artemis = "$env:USERPROFILE\develop\artemis"
)

$ErrorActionPreference = 'Continue'
$Dev = "$env:USERPROFILE\develop\.attendo-dev"
New-Item -ItemType Directory -Force $Dev | Out-Null
$Host.UI.RawUI.WindowTitle = "Attendo ARTEMIS: $Step"
$env:PYTHONUTF8 = '1'
$env:PYTHONIOENCODING = 'utf-8'

function Log([string]$Text) {
  $line = "$(Get-Date -Format HH:mm:ss) $Text"
  Write-Host $line
  Add-Content -Path "$Dev\artemis.log" -Value $line -Encoding UTF8
}

$tools = @(
  "$env:USERPROFILE\develop\flutter\bin",
  "$env:USERPROFILE\.local\bin",
  "$env:LOCALAPPDATA\Programs\uv",
  "$env:LOCALAPPDATA\Microsoft\WinGet\Links",
  "$env:LOCALAPPDATA\Android\Sdk\platform-tools",
  "$env:LOCALAPPDATA\Programs\platform-tools",
  "$env:ProgramFiles\nodejs"
) | Where-Object { Test-Path $_ }
$env:PATH = (($tools + @($env:PATH)) -join ';')
# The Firestore emulator needs Java 21. A java on PATH may be an old Oracle 8 (javapath), so prefer the
# JDK that Android Studio ships (21 in current versions) when it exists.
foreach ($jbr in @("$env:ProgramFiles\Android\Android Studio\jbr", "$env:LOCALAPPDATA\Programs\Android Studio\jbr")) {
  if (Test-Path "$jbr\bin\java.exe") { $env:JAVA_HOME = $jbr; $env:PATH = "$jbr\bin;$env:PATH"; break }
}

function Test-Port([int]$Port) {
  $c = New-Object System.Net.Sockets.TcpClient
  try { $c.Connect('127.0.0.1', $Port); return $true } catch { return $false } finally { $c.Dispose() }
}

function Get-Serial {
  $line = adb devices | Select-String "`tdevice$" | Select-Object -First 1
  if ($line) { return $line.ToString().Split("`t")[0] }
  return $null
}

function Invoke-Check {
  Log "=== check ==="
  $ok = $true
  foreach ($t in @('git', 'node', 'npm', 'java', 'adb', 'flutter', 'uv')) {
    $cmd = Get-Command $t -ErrorAction SilentlyContinue
    if ($cmd) { Log "  [OK] $t  $($cmd.Source)" } else { Log "  [THIEU] $t"; $ok = $false }
  }
  $jv = (cmd /c "java -version 2>&1" | Select-Object -First 1)
  if ($jv -match '"(\d+)') {
    if ([int]$Matches[1] -ge 21) { Log "  [OK] Java $($Matches[1])" } else { Log "  [THIEU] Java $($Matches[1]): Firebase Emulator can Java 21 (cai Android Studio ban moi hoac: winget install Microsoft.OpenJDK.21)"; $ok = $false }
  }
  $serial = Get-Serial
  if ($serial) { Log "  [OK] dien thoai $serial" } else { Log "  [THIEU] dien thoai: cam cap, mo khoa, bat Go loi USB"; $ok = $false }
  if (Test-Port 8000) { Log "  [OK] ARTEMIS dang chay o http://127.0.0.1:8000" } else { Log "  [THIEU] ARTEMIS: chay $Artemis\start.bat va de cua so do mo"; $ok = $false }
  $envFile = "$Artemis\.env"
  $hasKey = (Test-Path $envFile) -and (Select-String -Path $envFile -Pattern '^(GEMINI_API_KEY|GOOGLE_API_KEY)=\S+' -Quiet)
  if ($hasKey) { Log "  [OK] co khoa Gemini trong artemis\.env (khong in ra)" } else { Log "  [THIEU] khoa Gemini: dong GEMINI_API_KEY= trong $envFile dang trong"; $ok = $false }
  $devRun = Get-CimInstance Win32_Process -Filter "Name='dart.exe' OR Name='dartvm.exe'" -ErrorAction SilentlyContinue |
    Where-Object { $_.CommandLine -match 'run -d ' -and $_.CommandLine -notmatch 'web-server|windows' }
  if ($devRun) { Log "  [THIEU] cua so dev 'phone' van dang chay: dong cua so do truoc"; $ok = $false } else { Log "  [OK] khong co cua so dev phone" }
  if ($ok) { Log "KIEM TRA: DAT" } else { Log "KIEM TRA: CON THIEU (xem dong [THIEU])" }
  return $ok
}

function Start-Emulator {
  if ((Test-Port 8080) -and (Test-Port 9099)) { Log "Emulator da chay san"; return $true }
  $tests = "$Repo\firebase\tests"
  if (-not (Test-Path "$tests\node_modules")) {
    Log "npm ci (firebase/tests), lan dau khoang 1 phut"
    Push-Location $tests; cmd /c "npm ci --no-audit --no-fund > `"$Dev\artemis-npm.log`" 2>&1"; Pop-Location
  }
  Log "Bat Firebase Emulator (auth, firestore), log: artemis-emulator.log"
  Start-Process -FilePath 'cmd.exe' -WorkingDirectory $tests -WindowStyle Minimized `
    -ArgumentList "/c npx firebase emulators:start --config ..\firebase.json --project attendo-app-2611 --only auth,firestore > `"$Dev\artemis-emulator.log`" 2>&1" | Out-Null
  for ($i = 0; $i -lt 60; $i++) {
    if ((Test-Port 8080) -and (Test-Port 9099)) { Log "Emulator san sang"; return $true }
    Start-Sleep -Seconds 3
  }
  Log "LOI: Emulator khong len sau 3 phut, xem artemis-emulator.log"
  return $false
}

function Invoke-Seed {
  Log "Nap du lieu mau vao Emulator"
  Push-Location "$Repo\firebase\tests"
  cmd /c "node seed-demo.mjs --reset --live-now --demo > `"$Dev\artemis-seed.log`" 2>&1"
  $code = $LASTEXITCODE
  Pop-Location
  Get-Content "$Dev\artemis-seed.log" -Tail 3 | ForEach-Object { Log "  $_" }
  return ($code -eq 0)
}

function Install-App([string]$Portal) {
  $serial = Get-Serial
  foreach ($port in @('8080', '9099')) { adb -s $serial reverse "tcp:$port" "tcp:$port" | Out-Null }
  $defines = "--dart-define=EMULATOR_HOST=127.0.0.1"
  if ($Portal -eq 'student') { $defines += " --dart-define=PORTAL=student" }
  $tokenFile = "$env:USERPROFILE\develop\attendo-config\app-check-debug-token.txt"
  if (Test-Path $tokenFile) {
    $tok = (Get-Content $tokenFile -Raw).Trim()
    if ($tok -match '^[A-Za-z0-9-]{20,64}$') { $defines += " --dart-define=APP_CHECK_DEBUG_TOKEN=$tok" }
  }
  Log "Dung app ($Portal, noi Emulator), khoang 2-4 phut, log: artemis-build.log"
  foreach ($pkg in @("$Repo\packages\core", "$Repo\mobile")) { Push-Location $pkg; cmd /c "flutter pub get > nul 2>&1"; Pop-Location }
  Push-Location "$Repo\mobile"
  cmd /c "flutter build apk --debug $defines > `"$Dev\artemis-build.log`" 2>&1"
  $code = $LASTEXITCODE
  Pop-Location
  if ($code -ne 0) { Log "LOI: dung app hong, xem artemis-build.log"; return $false }
  Log "Cai app len dien thoai (xoa du lieu cu de dang nhap lai voi Emulator)"
  adb -s $serial shell pm clear app.attendo | Out-Null
  adb -s $serial install -r "$Repo\mobile\build\app\outputs\flutter-apk\app-debug.apk" *> "$Dev\artemis-install.log"
  adb -s $serial shell pm clear app.attendo | Out-Null
  adb -s $serial shell monkey -p app.attendo -c android.intent.category.LAUNCHER 1 | Out-Null
  return $true
}

function Write-TestEnv([string]$Email) {
  $serial = Get-Serial
  @(
    "# Written by tool/artemis/run-e2e.ps1 (no secrets here). Not committed.",
    "ARTEMIS_BASE_URL=http://127.0.0.1:8000",
    "ARTEMIS_DEVICE=$serial",
    "QA_APP_PACKAGE=app.attendo",
    "QA_TEST_EMAIL=$Email",
    "QA_TEST_PASSWORD=Demo@123",
    "QA_EXPECT_QR_SECONDS=12",
    "QA_RESEED_CMD=node ../firebase/tests/seed-demo.mjs --reset --live-now --demo"
  ) | Set-Content -Path "$Repo\e2e_test\.env" -Encoding UTF8
}

function Wait-Login([string]$Email) {
  Log "CAN BAN: tren dien thoai dang nhap $Email / Demo@123 (o Email va Mat khau, KHONG bam Google)."
  Log "         Vao duoc man dau tien thi quay lai day bam Enter."
  [void](Read-Host "Bam Enter khi da dang nhap xong")
  Log "Da dang nhap $Email"
}

function Invoke-Pytest([string]$Name, [string[]]$TestArgs) {
  Push-Location "$Repo\e2e_test"
  if (-not (Test-Path '.venv')) { Log "uv sync (e2e_test), lan dau khoang 1 phut"; cmd /c "uv sync > `"$Dev\artemis-uv.log`" 2>&1" }
  $out = "$Dev\artemis-pytest-$Name.log"
  Log "Chay test $Name x$Count, theo doi o $out"
  $all = @('run', 'pytest') + $TestArgs + @("--count=$Count", '-p', 'no:randomly', '-rA', "--junitxml=runs/junit-$Name.xml")
  cmd /c "uv $($all -join ' ') > `"$out`" 2>&1"
  Pop-Location
  Get-Content $out -Tail 15 -Encoding UTF8 | ForEach-Object { Log "  $_" }
}

function Invoke-Report {
  Push-Location "$Repo\e2e_test"
  New-Item -ItemType Directory -Force "$Repo\evidence\artemis" | Out-Null
  cmd /c "uv run python report.py ..\evidence\artemis\results.md > `"$Dev\artemis-report.log`" 2>&1"
  Pop-Location
  Log "Bang ket qua: evidence\artemis\results.md"
}

function Invoke-Suite([string]$Portal) {
  if (-not (Start-Emulator)) { return }
  if (-not (Invoke-Seed)) { Log "LOI: nap du lieu hong, xem artemis-seed.log"; return }
  if (-not (Install-App $Portal)) { return }
  if ($Portal -eq 'student') {
    Write-TestEnv 'dung101@fpt.edu.vn'; Wait-Login 'dung101@fpt.edu.vn'
    Invoke-Pytest 'student' @('-m', 'student')
  } else {
    Write-TestEnv 'quanm@fe.edu.vn'; Wait-Login 'quanm@fe.edu.vn'
    Invoke-Pytest 'lecturer' @('test_auth.py', 'test_detail.py', 'test_import.py', 'test_profile.py', 'test_session.py')
  }
}

Log "===== run-e2e.ps1 -Step $Step (Count=$Count) ====="
switch ($Step) {
  'check' { [void](Invoke-Check) }
  'lecturer' { if (Invoke-Check) { Invoke-Suite 'lecturer'; Invoke-Report } }
  'student' { if (Invoke-Check) { Invoke-Suite 'student'; Invoke-Report } }
  'lab3' { if (Invoke-Check) { Invoke-Suite 'lecturer'; Invoke-Suite 'student'; Invoke-Report } }
  'report' { Invoke-Report }
  'stop' {
    Get-CimInstance Win32_Process -Filter "Name='java.exe'" | Where-Object { $_.CommandLine -match 'cloud-firestore-emulator|firebase' } |
      ForEach-Object { Stop-Process -Id $_.ProcessId -Force }
    Get-CimInstance Win32_Process -Filter "Name='node.exe'" | Where-Object { $_.CommandLine -match 'emulators:start' } |
      ForEach-Object { Stop-Process -Id $_.ProcessId -Force }
    Log "Da tat Emulator"
  }
}
Log "===== xong -Step $Step ====="
