@echo off
setlocal EnableExtensions DisableDelayedExpansion
title Build fpylll 0.6.4 cp311 win_amd64 wheel - revision 8

set "SCRIPT_REVISION=8"
set "FPYLLL_VERSION=0.6.4"
set "FPLLL_VERSION=5.5.0"
set "BUILD_ROOT=%PUBLIC%\fpylll-wheel-build"
set "MSYS_ROOT=%BUILD_ROOT%\msys64"
set "OUT_DIR=%~dp0dist"
set "SFX=%BUILD_ROOT%\msys2-x86_64-latest.sfx.exe"
set "B64_FILE=%BUILD_ROOT%\build-fpylll-win311.b64"
set "LOG=%~dp0fpylll-build.log"
set "PYTHON_FILE=%BUILD_ROOT%\target-python.txt"
set "MSYS_URL=https://repo.msys2.org/distrib/msys2-x86_64-latest.sfx.exe"
set "MSYS_FALLBACK_URL=https://repo.msys2.org/distrib/x86_64/msys2-base-x86_64-20260611.sfx.exe"
set "MSYS_GITHUB_URL=https://github.com/msys2/msys2-installer/releases/download/2026-06-11/msys2-base-x86_64-20260611.sfx.exe"

if /I "%~1"=="clean" (
  echo Removing %BUILD_ROOT% ...
  rmdir /s /q "%BUILD_ROOT%" 2>nul
  rmdir /s /q "%OUT_DIR%" 2>nul
)

if not exist "%BUILD_ROOT%" mkdir "%BUILD_ROOT%" || (echo ERROR: Cannot create %BUILD_ROOT%.& exit /b 1)
if not exist "%OUT_DIR%" mkdir "%OUT_DIR%" || (echo ERROR: Cannot create %OUT_DIR%.& exit /b 1)

rem Use PYTHON_EXE when supplied; otherwise use the currently active `python`.
if defined PYTHON_EXE (
  set "TARGET_PYTHON=%PYTHON_EXE%"
) else (
  set "TARGET_PYTHON=python"
)

"%TARGET_PYTHON%" -c "import sys; print(sys.executable)" > "%PYTHON_FILE%" 2>nul
if errorlevel 1 (
  echo ERROR: Could not run the selected Python. Activate your Python 3.11 environment first,
  echo        or set PYTHON_EXE to the full path of python.exe.
  exit /b 1
)
set /p "TARGET_PYTHON_WIN="<"%PYTHON_FILE%"

"%TARGET_PYTHON_WIN%" -c "import struct,sys; assert sys.platform=='win32'; assert sys.implementation.name=='cpython'; assert sys.version_info[:2]==(3,11); assert struct.calcsize('P')==8" 2>nul
if errorlevel 1 (
  echo ERROR: The selected interpreter must be native 64-bit CPython 3.11 for Windows.
  echo Selected: %TARGET_PYTHON_WIN%
  "%TARGET_PYTHON_WIN%" -c "import platform,sys; print(sys.version); print(platform.platform())"
  exit /b 1
)

echo Target Python: %TARGET_PYTHON_WIN%

where certutil.exe >nul 2>nul || (echo ERROR: certutil.exe is required and is normally included with Windows 10.& exit /b 1)

if not exist "%MSYS_ROOT%\usr\bin\bash.exe" (
  echo Downloading portable MSYS2...
  call :download "%MSYS_URL%" "%SFX%"
  if errorlevel 1 (
    echo Primary MSYS2 link failed; trying the dated official archive...
    call :download "%MSYS_FALLBACK_URL%" "%SFX%"
  )
  if errorlevel 1 (
    echo Official repository failed; trying the official GitHub release...
    call :download "%MSYS_GITHUB_URL%" "%SFX%"
  )
  if errorlevel 1 (echo ERROR: Could not download MSYS2 from any official source.& exit /b 1)
  call :validate_sfx "%SFX%" || (echo ERROR: The downloaded MSYS2 archive is missing or unexpectedly small.& del /q "%SFX%" 2>nul& exit /b 1)
  echo Extracting MSYS2...
  start "" /wait "%SFX%" -y -o"%BUILD_ROOT%"
  if not exist "%MSYS_ROOT%\usr\bin\bash.exe" (echo ERROR: MSYS2 extraction failed.& exit /b 1)
)

set "MSYSTEM=UCRT64"
set "CHERE_INVOKING=1"
set "MSYS2_PATH_TYPE=inherit"
set "FPYLLL_OUT_WIN=%OUT_DIR%"

echo Initializing and updating MSYS2...
"%MSYS_ROOT%\usr\bin\bash.exe" -lc "true" || (echo ERROR: MSYS2 initialization failed.& exit /b 1)
"%MSYS_ROOT%\usr\bin\bash.exe" -lc "pacman -Syuu --noconfirm"
"%MSYS_ROOT%\usr\bin\bash.exe" -lc "pacman -Syuu --noconfirm" || (echo ERROR: MSYS2 update failed.& exit /b 1)

rem Reconstruct the embedded Bash build payload using cmd.exe and MSYS2 coreutils.
>"%B64_FILE%" (
  echo IyEvdXNyL2Jpbi9lbnYgYmFzaApzZXQgLUVldW8gcGlwZWZhaWwKCkZQWUxMTF9WRVJTSU9OPSIk
  echo e0ZQWUxMTF9WRVJTSU9OOi0wLjYuNH0iCkZQTExMX1ZFUlNJT049IiR7RlBMTExfVkVSU0lPTjot
  echo NS41LjB9IgpGUExMTF9NSU5HV19QQVRDSF9DT01NSVQ9ImM5MTRkMGQ4ZGE2MDFhZDhhMjM3MjFj
  echo YjliNTFmOTY3MjAxNGM0ZjEiClRBUkdFVF9QWVRIT05fV0lOPSIke1RBUkdFVF9QWVRIT05fV0lO
  echo Oj9UQVJHRVRfUFlUSE9OX1dJTiBpcyBub3Qgc2V0fSIKT1VUX1dJTj0iJHtGUFlMTExfT1VUX1dJ
  echo Tjo/RlBZTExMX09VVF9XSU4gaXMgbm90IHNldH0iClBZVEhPTj0iJChjeWdwYXRoIC11ICIkVEFS
  echo R0VUX1BZVEhPTl9XSU4iKSIKT1VUX0RJUj0iJChjeWdwYXRoIC11ICIkT1VUX1dJTiIpIgpXT1JL
  echo X0RJUj0iL3RtcC9mcHlsbGwtd2luMzExLXdoZWVsLWJ1aWxkIgpKT0JTPSIke05VTUJFUl9PRl9Q
  echo Uk9DRVNTT1JTOi0yfSIKCnN0ZXAoKSB7IHByaW50ZiAnXG49PT09ICVzID09PT1cbicgIiQqIjsg
  echo fQpkaWUoKSB7IHByaW50ZiAnXG5FUlJPUjogJXNcbicgIiQqIiA+JjI7IGV4aXQgMTsgfQoKZXhw
  echo b3J0IFBBVEg9Ii91Y3J0NjQvYmluOi91c3IvYmluOiR7UEFUSDotfSIKZXhwb3J0IFBLR19DT05G
  echo SUdfUEFUSD0iL3VjcnQ2NC9saWIvcGtnY29uZmlnIgpleHBvcnQgQ0M9Z2NjCmV4cG9ydCBDWFg9
  echo ZysrCmV4cG9ydCBBUj1hcgpleHBvcnQgUkFOTElCPXJhbmxpYgpleHBvcnQgU1RSSVA9c3RyaXAK
  echo IyBDUHl0aG9uJ3MgV2luZG93cyBweWNvbmZpZy5oIG9ubHkgc2VsZWN0cyBpdHMgNjQtYml0IEFC
  echo SSBicmFuY2ggd2hlbgojIE1TX1dJTjY0IGlzIGRlZmluZWQuIE1TVkMgZGVmaW5lcyBpdCBpbmRp
  echo cmVjdGx5OyBNaW5HVyBkb2VzIG5vdC4KZXhwb3J0IENGTEFHUz0iLU8yIC1waXBlIC1ETVNfV0lO
  echo NjQ9MSAtRF9fVVNFX01JTkdXX0FOU0lfU1RESU89MSIKZXhwb3J0IENYWEZMQUdTPSItTzIgLXBp
  echo cGUgLURNU19XSU42ND0xIC1EX19VU0VfTUlOR1dfQU5TSV9TVERJTz0xIgpleHBvcnQgTERGTEFH
  echo Uz0iLUwvdWNydDY0L2xpYiIKCnN0ZXAgIlZhbGlkYXRlIHRhcmdldCBXaW5kb3dzIFB5dGhvbiIK
  echo W1sgLXggIiRQWVRIT04iIF1dIHx8IGRpZSAiUHl0aG9uIGV4ZWN1dGFibGUgbm90IGZvdW5kOiAk
  echo VEFSR0VUX1BZVEhPTl9XSU4iCiIkUFlUSE9OIiAtIDw8J1BZJwppbXBvcnQgcGxhdGZvcm0KaW1w
  echo b3J0IHN0cnVjdAppbXBvcnQgc3lzCgphc3NlcnQgc3lzLnBsYXRmb3JtID09ICJ3aW4zMiIsIGYi
  echo RXhwZWN0ZWQgbmF0aXZlIFdpbmRvd3MgUHl0aG9uLCBnb3Qge3N5cy5wbGF0Zm9ybSFyfSIKYXNz
  echo ZXJ0IHN5cy5pbXBsZW1lbnRhdGlvbi5uYW1lID09ICJjcHl0aG9uIiwgIkNQeXRob24gaXMgcmVx
  echo dWlyZWQiCmFzc2VydCBzeXMudmVyc2lvbl9pbmZvWzoyXSA9PSAoMywgMTEpLCBmIlB5dGhvbiAz
  echo LjExIGlzIHJlcXVpcmVkLCBnb3Qge3N5cy52ZXJzaW9uLnNwbGl0KClbMF19Igphc3NlcnQgc3Ry
  echo dWN0LmNhbGNzaXplKCJQIikgPT0gOCwgIjY0LWJpdCBQeXRob24gaXMgcmVxdWlyZWQiCnByaW50
  echo KCJFeGVjdXRhYmxlOiIsIHN5cy5leGVjdXRhYmxlKQpwcmludCgiVmVyc2lvbjoiLCBzeXMudmVy
  echo c2lvbi5yZXBsYWNlKCJcbiIsICIgIikpCnByaW50KCJQbGF0Zm9ybToiLCBwbGF0Zm9ybS5wbGF0
  echo Zm9ybSgpKQpQWQoKVEFSR0VUX05VTVBZX1ZFUlNJT049IiQoIiRQWVRIT04iIC1jICdpbXBvcnQg
  echo bnVtcHk7IHByaW50KG51bXB5Ll9fdmVyc2lvbl9fKScgMj4vZGV2L251bGwgfHwgdHJ1ZSkiCmlm
  echo IFtbIC16ICIkVEFSR0VUX05VTVBZX1ZFUlNJT04iIF1dOyB0aGVuCiAgVEFSR0VUX05VTVBZX1ZF
  echo UlNJT049IjIuMC4yIgpmaQpwcmludGYgJ1RhcmdldCBOdW1QeTogJXNcbicgIiRUQVJHRVRfTlVN
  echo UFlfVkVSU0lPTiIKZXhwb3J0IFRBUkdFVF9OVU1QWV9WRVJTSU9OCgpzdGVwICJJbnN0YWxsIE1T
  echo WVMyIFVDUlQ2NCBjb21waWxlciBhbmQgbmF0aXZlIGxpYnJhcmllcyIKcGFjbWFuIC1TIC0tbmVl
  echo ZGVkIC0tbm9jb25maXJtIFwKICBiYXNlLWRldmVsIGdpdCBjdXJsIHRhciBwYXRjaCBhdXRvY29u
  echo ZiBhdXRvbWFrZSBsaWJ0b29sIHBrZ2NvbmYgXAogIG1pbmd3LXc2NC11Y3J0LXg4Nl82NC1nY2Mg
  echo XAogIG1pbmd3LXc2NC11Y3J0LXg4Nl82NC1nbXAgXAogIG1pbmd3LXc2NC11Y3J0LXg4Nl82NC1t
  echo cGZyIFwKICBtaW5ndy13NjQtdWNydC14ODZfNjQtcGtnY29uZgoKbWtkaXIgLXAgIiRPVVRfRElS
  echo IgpybSAtcmYgIiRXT1JLX0RJUiIKbWtkaXIgLXAgIiRXT1JLX0RJUiIKY2QgIiRXT1JLX0RJUiIK
  echo CnN0ZXAgIkNyZWF0ZSBpc29sYXRlZCBDUHl0aG9uIDMuMTEgYnVpbGQgZW52aXJvbm1lbnQiCmJ1
  echo aWxkX2Vudl93aW49IiQoY3lncGF0aCAtdyAiJFdPUktfRElSL2J1aWxkLWVudjMxMSIpIgoiJFBZ
  echo VEhPTiIgLW0gdmVudiAiJGJ1aWxkX2Vudl93aW4iIHx8IGRpZSAiQ291bGQgbm90IGNyZWF0ZSB0
  echo aGUgaXNvbGF0ZWQgYnVpbGQgZW52aXJvbm1lbnQiCkJVSUxEX1BZVEhPTj0iJFdPUktfRElSL2J1
  echo aWxkLWVudjMxMS9TY3JpcHRzL3B5dGhvbi5leGUiCltbIC14ICIkQlVJTERfUFlUSE9OIiBdXSB8
  echo fCBkaWUgIkJ1aWxkLWVudmlyb25tZW50IHB5dGhvbi5leGUgd2FzIG5vdCBjcmVhdGVkIgoiJEJV
  echo SUxEX1BZVEhPTiIgLW0gcGlwIGluc3RhbGwgLS11cGdyYWRlIFwKICAicGlwPDI3IiBcCiAgInNl
  echo dHVwdG9vbHM9PTgzLjAuMCIgXAogICJ3aGVlbD09MC40Ny4wIiBcCiAgIkN5dGhvbj09My4xLjQi
  echo IFwKICAibnVtcHk9PSR7VEFSR0VUX05VTVBZX1ZFUlNJT059IiBcCiAgImN5c2lnbmFscz49MS4x
  echo Mi41IiBcCiAgImRlbHZld2hlZWw+PTEuMTAiCgppZiBwa2ctY29uZmlnIC0tZXhpc3RzICJmcGxs
  echo bCA+PSAke0ZQTExMX1ZFUlNJT059IjsgdGhlbgogIHN0ZXAgIlJldXNlIHBhdGNoZWQgZnBsbGwg
  echo ZnJvbSB0aGUgcHJpdmF0ZSBVQ1JUNjQgdG9vbGNoYWluIgogIHBrZy1jb25maWcgLS1tb2R2ZXJz
  echo aW9uIGZwbGxsCmVsc2UKICBzdGVwICJCdWlsZCBmcGxsbCAke0ZQTExMX1ZFUlNJT059IGZvciBu
  echo YXRpdmUgV2luZG93cyIKICBnaXQgY2xvbmUgLS1kZXB0aCAxIC0tYnJhbmNoICIkRlBMTExfVkVS
  echo U0lPTiIgaHR0cHM6Ly9naXRodWIuY29tL2ZwbGxsL2ZwbGxsLmdpdCBmcGxsbAogIGNkIGZwbGxs
  echo CiAgcGF0Y2hfZmlsZT0iJFdPUktfRElSL2ZwbGxsLW1pbmd3LSR7RlBMTExfTUlOR1dfUEFUQ0hf
  echo Q09NTUlUfS5wYXRjaCIKICBjdXJsIC0tZmFpbCAtLWxvY2F0aW9uIC0tcmV0cnkgMyAtLXJldHJ5
  echo LWRlbGF5IDIgXAogICAgImh0dHBzOi8vZ2l0aHViLmNvbS9mcGxsbC9mcGxsbC9jb21taXQvJHtG
  echo UExMTF9NSU5HV19QQVRDSF9DT01NSVR9LnBhdGNoIiBcCiAgICAtLW91dHB1dCAiJHBhdGNoX2Zp
  echo bGUiCiAgZ2l0IGFwcGx5IC0tY2hlY2sgIiRwYXRjaF9maWxlIgogIGdpdCBhcHBseSAiJHBhdGNo
  echo X2ZpbGUiCiAgLi9hdXRvZ2VuLnNoCiAgLi9jb25maWd1cmUgXAogICAgLS1wcmVmaXg9L3VjcnQ2
  echo NCBcCiAgICAtLWRpc2FibGUtc3RhdGljIFwKICAgIC0td2l0aC1xZD1ubyBcCiAgICAtLXdpdGgt
  echo bWF4LXBhcmFsbGVsLWVudW0tZGltPTAKICBtYWtlIC1qIiRKT0JTIgogIG1ha2UgaW5zdGFsbAog
  echo IGNkICIkV09SS19ESVIiCmZpCgpbWyAtZiAvdWNydDY0L2xpYi9wa2djb25maWcvZnBsbGwucGMg
  echo XV0gfHwgZGllICJmcGxsbC5wYyB3YXMgbm90IGluc3RhbGxlZCIKcGtnLWNvbmZpZyAtLW1vZHZl
  echo cnNpb24gZnBsbGwKCnN0ZXAgIlBhdGNoIGZwbGxsIDUuNS4wIG1hdGggY29uc3RhbnQgZm9yIE1p
  echo bkdXIEMrKyIKZHBlX2hlYWRlcj0iL3VjcnQ2NC9pbmNsdWRlL2ZwbGxsL25yL2RwZS5oIgpbWyAt
  echo ZiAiJGRwZV9oZWFkZXIiIF1dIHx8IGRpZSAiZnBsbGwgZHBlLmggd2FzIG5vdCBpbnN0YWxsZWQi
  echo CmlmIGdyZXAgLXEgJ01fTE4yJyAiJGRwZV9oZWFkZXIiOyB0aGVuCiAgIyBNaW5HVydzIHN0cmlj
  echo dCBDKysgaGVhZGVycyBkbyBub3QgZ3VhcmFudGVlIHRoZSBub24tc3RhbmRhcmQgTV9MTjIgbWFj
  echo cm8uCiAgIyBmcGxsbCBhbHJlYWR5IHVzZXMgbG9nKDIuMCkgZm9yIHRoZSBlcXVpdmFsZW50IG9w
  echo ZXJhdGlvbiBlbHNld2hlcmUuCiAgc2VkIC1pICdzL1w8TV9MTjJcPi9sb2coMi4wKS9nJyAiJGRw
  echo ZV9oZWFkZXIiCmZpCmdyZXAgLXEgJ01fTE4yJyAiJGRwZV9oZWFkZXIiICYmIGRpZSAiQ291bGQg
  echo bm90IHJlbW92ZSBNX0xOMiBmcm9tIGZwbGxsIGRwZS5oIgpncmVwIC1xICdEUEVfRVhQKHkpKS4q
  echo bG9nKDIuMCknICIkZHBlX2hlYWRlciIgfHwgZGllICJUaGUgZnBsbGwgZHBlLmggbWF0aCBwYXRj
  echo aCB3YXMgbm90IGFwcGxpZWQiCgpzdGVwICJCdWlsZCBmcHlsbGwgJHtGUFlMTExfVkVSU0lPTn0g
  echo YWdhaW5zdCB0aGUgdGFyZ2V0IENQeXRob24gMy4xMSBBQkkiCmdpdCBjbG9uZSAtLWRlcHRoIDEg
  echo LS1icmFuY2ggIiRGUFlMTExfVkVSU0lPTiIgaHR0cHM6Ly9naXRodWIuY29tL2ZwbGxsL2ZweWxs
  echo bC5naXQgZnB5bGxsCmNkIGZweWxsbAoKIyBQYXRjaCBleGFjdCB1cHN0cmVhbSBzZXR1cC5weSBz
  echo dGF0ZW1lbnRzLiBUaGUgbmF0aXZlIGxpYnJhcmllcyBjb21lIGZyb20KIyBVQ1JUNjQsIHdoaWxl
  echo IFB5dGhvbiBoZWFkZXJzL2ltcG9ydCBsaWJyYXJpZXMgY29tZSBmcm9tIHRoZSB0YXJnZXQgQ1B5
  echo dGhvbi4KIiRCVUlMRF9QWVRIT04iIC0gPDwnUFknCmltcG9ydCBvcwpmcm9tIHBhdGhsaWIgaW1w
  echo b3J0IFBhdGgKCnBhdGggPSBQYXRoKCJzZXR1cC5weSIpCnRleHQgPSBwYXRoLnJlYWRfdGV4dChl
  echo bmNvZGluZz0idXRmLTgiKQp0YXJnZXRfbnVtcHkgPSBvcy5lbnZpcm9uWyJUQVJHRVRfTlVNUFlf
  echo VkVSU0lPTiJdCnJlcGxhY2VtZW50cyA9IHsKICAgICdpbmNsdWRlX2RpcnMgPSBbb3MucGF0aC5q
  echo b2luKHN5cy5wcmVmaXgsICJpbmNsdWRlIildJzogJycnaW5jbHVkZV9kaXJzID0gWwogICAgICAg
  echo ICAgICBvcy5wYXRoLmpvaW4ob3MuZW52aXJvbi5nZXQoIkZQWUxMTF9QUkVGSVgiLCBzeXMucHJl
  echo Zml4KSwgImluY2x1ZGUiKSwKICAgICAgICAgICAgb3MucGF0aC5qb2luKHN5cy5iYXNlX3ByZWZp
  echo eCwgImluY2x1ZGUiKSwKICAgICAgICAgICAgb3MucGF0aC5qb2luKHN5cy5wcmVmaXgsICJpbmNs
  echo dWRlIiksCiAgICAgICAgXScnJywKICAgICdsaWJyYXJ5X2RpcnMgPSBbb3MucGF0aC5qb2luKHN5
  echo cy5leGVjX3ByZWZpeCwgImxpYiIpXSc6ICcnJ2xpYnJhcnlfZGlycyA9IFsKICAgICAgICAgICAg
  echo b3MucGF0aC5qb2luKG9zLmVudmlyb24uZ2V0KCJGUFlMTExfUFJFRklYIiwgc3lzLmV4ZWNfcHJl
  echo Zml4KSwgImxpYiIpLAogICAgICAgICAgICBvcy5wYXRoLmpvaW4oc3lzLmJhc2VfcHJlZml4LCAi
  echo bGlicyIpLAogICAgICAgICAgICBvcy5wYXRoLmpvaW4oc3lzLmJhc2VfcHJlZml4LCAibGliIiks
  echo CiAgICAgICAgICAgIG9zLnBhdGguam9pbihzeXMuZXhlY19wcmVmaXgsICJsaWJzIiksCiAgICAg
  echo ICAgICAgIG9zLnBhdGguam9pbihzeXMuZXhlY19wcmVmaXgsICJsaWIiKSwKICAgICAgICBdJycn
  echo LAogICAgJyJkZWZpbmVfbWFjcm9zIjogWygiQ1lUSE9OX0VYVEVSTl9DIiwgXCdleHRlcm4gIkMr
  echo KyJcJyldLCc6ICciZGVmaW5lX21hY3JvcyI6IFsoIkNZVEhPTl9FWFRFUk5fQyIsIFwnZXh0ZXJu
  echo ICJDKysiXCcpLCAoIk1TX1dJTjY0IiwgIjEiKV0sJywKICAgICcibGlicmFyaWVzIjogWyJnbXAi
  echo XSwnOiAnImxpYnJhcmllcyI6IFsiZ21wIl0sXG4gICAgICAgICAgICAgICAgImRlZmluZV9tYWNy
  echo b3MiOiBbKCJNU19XSU42NCIsICIxIildLCcsCiAgICAnICAgICoqYXV4X3NldHVwX2t3ZHNcbic6
  echo IGYiIiIgICAgaW5zdGFsbF9yZXF1aXJlcz1bCiAgICAgICAgImN5c2lnbmFscz49MS4xMi41IiwK
  echo ICAgICAgICAibnVtcHk9PXt0YXJnZXRfbnVtcHl9IiwKICAgIF1cbiIiIiwKfQpmb3Igb2xkLCBu
  echo ZXcgaW4gcmVwbGFjZW1lbnRzLml0ZW1zKCk6CiAgICBpZiBvbGQgbm90IGluIHRleHQ6CiAgICAg
  echo ICAgcmFpc2UgU3lzdGVtRXhpdChmIkV4cGVjdGVkIHNldHVwLnB5IHRleHQgbm90IGZvdW5kOiB7
  echo b2xkfSIpCiAgICB0ZXh0ID0gdGV4dC5yZXBsYWNlKG9sZCwgbmV3LCAxKQpwYXRoLndyaXRlX3Rl
  echo eHQodGV4dCwgZW5jb2Rpbmc9InV0Zi04IikKUFkKCmdyZXAgLXEgJ01TX1dJTjY0JyBzZXR1cC5w
  echo eSB8fCBkaWUgIkNvdWxkIG5vdCBwYXRjaCBmcHlsbGwgc2V0dXAucHkgZm9yIDY0LWJpdCBNaW5H
  echo VyIKZ3JlcCAtcSAnRlBZTExMX1BSRUZJWCcgc2V0dXAucHkgfHwgZGllICJDb3VsZCBub3QgcGF0
  echo Y2ggZnB5bGxsIHNldHVwLnB5IGZvciB0aGUgVUNSVDY0IHByZWZpeCIKZ3JlcCAtcSAnY3lzaWdu
  echo YWxzPj0xLjEyLjUnIHNldHVwLnB5IHx8IGRpZSAiQ291bGQgbm90IGFkZCB0aGUgY3lzaWduYWxz
  echo IHJ1bnRpbWUgZGVwZW5kZW5jeSIKZ3JlcCAtcSAibnVtcHk9PSR7VEFSR0VUX05VTVBZX1ZFUlNJ
  echo T059IiBzZXR1cC5weSB8fCBkaWUgIkNvdWxkIG5vdCBhZGQgdGhlIE51bVB5IHJ1bnRpbWUgZGVw
  echo ZW5kZW5jeSIKZ3JlcCAtcSAnXCpcKmF1eF9zZXR1cF9rd2RzJyBzZXR1cC5weSAmJiBkaWUgIkNv
  echo bmRpdGlvbmFsIHJ1bnRpbWUgbWV0YWRhdGEgaXMgc3RpbGwgcHJlc2VudCIKCmNhdCA+IHNldHVw
  echo LmNmZyA8PCdDRkcnCltidWlsZF9leHRdCmNvbXBpbGVyID0gbWluZ3czMgpDRkcKCmV4cG9ydCBG
  echo UFlMTExfUFJFRklYPSIkKGN5Z3BhdGggLXcgL3VjcnQ2NCkiCmV4cG9ydCBIQVZFX1FEPTAKZXhw
  echo b3J0IEhBVkVfTE9OR19ET1VCTEU9MQpleHBvcnQgSEFWRV9OVU1QWT0xCmV4cG9ydCBTRVRVUFRP
  echo T0xTX1VTRV9ESVNUVVRJTFM9bG9jYWwKCnN0ZXAgIlByZWZsaWdodCBDUHl0aG9uIGhlYWRlciBB
  echo Qkkgd2l0aCBNaW5HVyIKcHl0aG9uX2luY2x1ZGVfd2luPSIkKCIkQlVJTERfUFlUSE9OIiAtYyAn
  echo aW1wb3J0IHN5c2NvbmZpZzsgcHJpbnQoc3lzY29uZmlnLmdldF9wYXRoKCJpbmNsdWRlIikpJyki
  echo CnB5dGhvbl9pbmNsdWRlPSIkKGN5Z3BhdGggLXUgIiRweXRob25faW5jbHVkZV93aW4iKSIKY2F0
  echo ID4gIiRXT1JLX0RJUi9weXRob24tYWJpLWNoZWNrLmMiIDw8J0MnCiNpbmNsdWRlIDxQeXRob24u
  echo aD4KI2lmbmRlZiBNU19XSU42NAojZXJyb3IgTVNfV0lONjQgaXMgbm90IGRlZmluZWQKI2VuZGlm
  echo CiNpZiBTSVpFT0ZfVk9JRF9QICE9IDgKI2Vycm9yIENQeXRob24gcHljb25maWcuaCBzZWxlY3Rl
  echo ZCBhIG5vbi02NC1iaXQgQUJJCiNlbmRpZgpfU3RhdGljX2Fzc2VydChzaXplb2Yodm9pZCAqKSA9
  echo PSA4LCAiQ29tcGlsZXIgaXMgbm90IHRhcmdldGluZyA2NC1iaXQgcG9pbnRlcnMiKTsKaW50IG1h
  echo aW4odm9pZCkgeyByZXR1cm4gMDsgfQpDCmdjYyAtRE1TX1dJTjY0PTEgLUkiJHB5dGhvbl9pbmNs
  echo dWRlIiAtYyAiJFdPUktfRElSL3B5dGhvbi1hYmktY2hlY2suYyIgLW8gIiRXT1JLX0RJUi9weXRo
  echo b24tYWJpLWNoZWNrLm8iCnByaW50ZiAnQ1B5dGhvbiBoZWFkZXIgQUJJIHByZWZsaWdodDogU0la
  echo RU9GX1ZPSURfUD04XG4nCgpybSAtcmYgYnVpbGQgZGlzdAoiJEJVSUxEX1BZVEhPTiIgc2V0dXAu
  echo cHkgLS12ZXJib3NlIGJkaXN0X3doZWVsCgptYXBmaWxlIC10IHJhd193aGVlbHMgPCA8KGZpbmQg
  echo ZGlzdCAtbWF4ZGVwdGggMSAtdHlwZSBmIC1uYW1lICJmcHlsbGwtJHtGUFlMTExfVkVSU0lPTn0t
  echo Y3AzMTEtY3AzMTEtd2luX2FtZDY0LndobCIgLXByaW50KQpbWyAkeyNyYXdfd2hlZWxzW0BdfSAt
  echo ZXEgMSBdXSB8fCBkaWUgIkV4cGVjdGVkIGV4YWN0bHkgb25lIGNwMzExLWNwMzExLXdpbl9hbWQ2
  echo NCB3aGVlbDsgZm91bmQgJHsjcmF3X3doZWVsc1tAXX0uIFJlZnVzaW5nIGFuIGluY29tcGF0aWJs
  echo ZSB3aGVlbC4iCnJhd193aGVlbD0iJHtyYXdfd2hlZWxzWzBdfSIKCnN0ZXAgIlZhbGlkYXRlIHdo
  echo ZWVsIHJ1bnRpbWUgZGVwZW5kZW5jeSBtZXRhZGF0YSIKcmF3X3doZWVsX3dpbj0iJChjeWdwYXRo
  echo IC13ICIkcmF3X3doZWVsIikiCiIkQlVJTERfUFlUSE9OIiAtICIkcmF3X3doZWVsX3dpbiIgIiRU
  echo QVJHRVRfTlVNUFlfVkVSU0lPTiIgPDwnUFknCmZyb20gZW1haWwucGFyc2VyIGltcG9ydCBCeXRl
  echo c1BhcnNlcgpmcm9tIHBhdGhsaWIgaW1wb3J0IFBhdGgKaW1wb3J0IHN5cwppbXBvcnQgemlwZmls
  echo ZQoKZnJvbSBwYWNrYWdpbmcucmVxdWlyZW1lbnRzIGltcG9ydCBSZXF1aXJlbWVudAoKd2hlZWwg
  echo PSBQYXRoKHN5cy5hcmd2WzFdKQp0YXJnZXRfbnVtcHkgPSBzeXMuYXJndlsyXQp3aXRoIHppcGZp
  echo bGUuWmlwRmlsZSh3aGVlbCkgYXMgYXJjaGl2ZToKICAgIG1ldGFkYXRhX25hbWVzID0gWwogICAg
  echo ICAgIG5hbWUgZm9yIG5hbWUgaW4gYXJjaGl2ZS5uYW1lbGlzdCgpCiAgICAgICAgaWYgbmFtZS5l
  echo bmRzd2l0aCgiLmRpc3QtaW5mby9NRVRBREFUQSIpCiAgICBdCiAgICBpZiBsZW4obWV0YWRhdGFf
  echo bmFtZXMpICE9IDE6CiAgICAgICAgcmFpc2UgU3lzdGVtRXhpdChmIkV4cGVjdGVkIG9uZSBNRVRB
  echo REFUQSBmaWxlLCBmb3VuZCB7bWV0YWRhdGFfbmFtZXMhcn0iKQogICAgbWV0YWRhdGEgPSBCeXRl
  echo c1BhcnNlcigpLnBhcnNlYnl0ZXMoYXJjaGl2ZS5yZWFkKG1ldGFkYXRhX25hbWVzWzBdKSkKCnJl
  echo cXVpcmVtZW50cyA9IFtSZXF1aXJlbWVudCh2YWx1ZSkgZm9yIHZhbHVlIGluIG1ldGFkYXRhLmdl
  echo dF9hbGwoIlJlcXVpcmVzLURpc3QiLCBbXSldCmJ5X25hbWUgPSB7cmVxdWlyZW1lbnQubmFtZS5s
  echo b3dlcigpOiByZXF1aXJlbWVudCBmb3IgcmVxdWlyZW1lbnQgaW4gcmVxdWlyZW1lbnRzfQoKaWYg
  echo ImN5c2lnbmFscyIgbm90IGluIGJ5X25hbWU6CiAgICByYWlzZSBTeXN0ZW1FeGl0KCJXaGVlbCBt
  echo ZXRhZGF0YSBkb2VzIG5vdCBkZWNsYXJlIGN5c2lnbmFscyIpCmlmICJudW1weSIgbm90IGluIGJ5
  echo X25hbWU6CiAgICByYWlzZSBTeXN0ZW1FeGl0KCJXaGVlbCBtZXRhZGF0YSBkb2VzIG5vdCBkZWNs
  echo YXJlIG51bXB5IikKaWYgc3RyKGJ5X25hbWVbIm51bXB5Il0uc3BlY2lmaWVyKSAhPSBmIj09e3Rh
  echo cmdldF9udW1weX0iOgogICAgcmFpc2UgU3lzdGVtRXhpdCgKICAgICAgICBmIldoZWVsIE51bVB5
  echo IHJlcXVpcmVtZW50IGlzIHtieV9uYW1lWydudW1weSddLnNwZWNpZmllciFzfSwgIgogICAgICAg
  echo IGYiZXhwZWN0ZWQgPT17dGFyZ2V0X251bXB5fSIKICAgICkKCnByaW50KCJXaGVlbCBydW50aW1l
  echo IGRlcGVuZGVuY2llczoiKQpmb3IgcmVxdWlyZW1lbnQgaW4gcmVxdWlyZW1lbnRzOgogICAgcHJp
  echo bnQoIiAiLCByZXF1aXJlbWVudCkKUFkKCnN0ZXAgIkJ1bmRsZSBNaW5HVywgZnBsbGwsIEdNUCwg
  echo YW5kIE1QRlIgcnVudGltZSBETExzIgpyZXBhaXJfZGlyPSIkV09SS19ESVIvcmVwYWlyZWQiCnJt
  echo IC1yZiAiJHJlcGFpcl9kaXIiCm1rZGlyIC1wICIkcmVwYWlyX2RpciIKdWNydF9iaW5fd2luPSIk
  echo KGN5Z3BhdGggLXcgL3VjcnQ2NC9iaW4pIgoiJEJVSUxEX1BZVEhPTiIgLW0gZGVsdmV3aGVlbCBz
  echo aG93IC0tYWRkLXBhdGggIiR1Y3J0X2Jpbl93aW4iICIkcmF3X3doZWVsIgoiJEJVSUxEX1BZVEhP
  echo TiIgLW0gZGVsdmV3aGVlbCByZXBhaXIgLXZ2IC0tYWRkLXBhdGggIiR1Y3J0X2Jpbl93aW4iIC13
  echo ICIkcmVwYWlyX2RpciIgIiRyYXdfd2hlZWwiCgptYXBmaWxlIC10IHJlcGFpcmVkX3doZWVscyA8
  echo IDwoZmluZCAiJHJlcGFpcl9kaXIiIC1tYXhkZXB0aCAxIC10eXBlIGYgLW5hbWUgImZweWxsbC0k
  echo e0ZQWUxMTF9WRVJTSU9OfS1jcDMxMS1jcDMxMS13aW5fYW1kNjQud2hsIiAtcHJpbnQpCltbICR7
  echo I3JlcGFpcmVkX3doZWVsc1tAXX0gLWVxIDEgXV0gfHwgZGllICJkZWx2ZXdoZWVsIGRpZCBub3Qg
  echo cHJvZHVjZSBleGFjdGx5IG9uZSBjcDMxMSBXaW5kb3dzIHdoZWVsIgpyZXBhaXJlZF93aGVlbD0i
  echo JHtyZXBhaXJlZF93aGVlbHNbMF19IgoKc3RlcCAiSW5zdGFsbCBhbmQgdGVzdCB0aGUgd2hlZWwg
  echo aW4gYSBjbGVhbiBDUHl0aG9uIDMuMTEgZW52aXJvbm1lbnQiCnNtb2tlX2Rpcj0iJFdPUktfRElS
  echo L3Ntb2tlMzExIgpzbW9rZV93aW49IiQoY3lncGF0aCAtdyAiJHNtb2tlX2RpciIpIgpybSAtcmYg
  echo IiRzbW9rZV9kaXIiCiIkUFlUSE9OIiAtbSB2ZW52ICIkc21va2Vfd2luIgpzbW9rZV9weXRob249
  echo IiRzbW9rZV9kaXIvU2NyaXB0cy9weXRob24uZXhlIgpbWyAteCAiJHNtb2tlX3B5dGhvbiIgXV0g
  echo fHwgZGllICJDb3VsZCBub3QgY3JlYXRlIHRoZSBzbW9rZS10ZXN0IHZpcnR1YWwgZW52aXJvbm1l
  echo bnQiCnJlcGFpcmVkX3dpbj0iJChjeWdwYXRoIC13ICIkcmVwYWlyZWRfd2hlZWwiKSIKIiRzbW9r
  echo ZV9weXRob24iIC1tIHBpcCBpbnN0YWxsIC0tdXBncmFkZSAicGlwPDI3IgojIEluc3RhbGwgb25s
  echo eSB0aGUgd2hlZWwuIEl0cyBtZXRhZGF0YSBtdXN0IHB1bGwgY3lzaWduYWxzIGFuZCBOdW1QeSBh
  echo dXRvbWF0aWNhbGx5LgoiJHNtb2tlX3B5dGhvbiIgLW0gcGlwIGluc3RhbGwgIiRyZXBhaXJlZF93
  echo aW4iCiIkc21va2VfcHl0aG9uIiAtbSBwaXAgY2hlY2sKIiRzbW9rZV9weXRob24iIC0gPDwnUFkn
  echo CmltcG9ydCBwbGF0Zm9ybQppbXBvcnQgc3lzCmltcG9ydCBmcHlsbGwubnVtcHkKZnJvbSBmcHls
  echo bGwgaW1wb3J0IEludGVnZXJNYXRyaXgsIExMTAoKQSA9IEludGVnZXJNYXRyaXguZnJvbV9tYXRy
  echo aXgoW1sxLCAxLCAxXSwgWy0xLCAwLCAyXSwgWzMsIDUsIDZdXSkKTExMLnJlZHVjdGlvbihBKQph
  echo c3NlcnQgQS5ucm93cyA9PSAzIGFuZCBBLm5jb2xzID09IDMKYXNzZXJ0IHN5cy52ZXJzaW9uX2lu
  echo Zm9bOjJdID09ICgzLCAxMSkKYXNzZXJ0IHN5cy5wbGF0Zm9ybSA9PSAid2luMzIiCnByaW50KCJm
  echo cHlsbGwgaW1wb3J0LCBOdW1QeSBleHRlbnNpb24sIGFuZCBMTEwgcmVkdWN0aW9uOiBPSyIpCnBy
  echo aW50KCJQeXRob246Iiwgc3lzLnZlcnNpb24ucmVwbGFjZSgiXG4iLCAiICIpKQpwcmludCgiUGxh
  echo dGZvcm06IiwgcGxhdGZvcm0ucGxhdGZvcm0oKSkKUFkKCnN0ZXAgIkNvcHkgdGhlIHZlcmlmaWVk
  echo IHdoZWVsIgpybSAtZiAiJE9VVF9ESVIiL2ZweWxsbC0qLndobApjcCAtZiAiJHJlcGFpcmVkX3do
  echo ZWVsIiAiJE9VVF9ESVIvIgoKY2F0ID4gIiRPVVRfRElSL0JVSUxELUlORk8udHh0IiA8PEVPRl9J
  echo TkZPCmZweWxsbDogJHtGUFlMTExfVkVSU0lPTn0KZnBsbGw6ICR7RlBMTExfVkVSU0lPTn0gcGx1
  echo cyBNaW5HVyBwYXRjaCAke0ZQTExMX01JTkdXX1BBVENIX0NPTU1JVH0KVGFyZ2V0IFB5dGhvbjog
  echo JCgiJFBZVEhPTiIgLWMgJ2ltcG9ydCBzeXM7IHByaW50KHN5cy52ZXJzaW9uLnJlcGxhY2UoIlxu
  echo IiwgIiAiKSknKQpUYXJnZXQgZXhlY3V0YWJsZTogJHtUQVJHRVRfUFlUSE9OX1dJTn0KVGFyZ2V0
  echo IE51bVB5IHVzZWQgZm9yIEFCSSB0ZXN0OiAke1RBUkdFVF9OVU1QWV9WRVJTSU9OfQpXaGVlbCB0
  echo YWc6IGNwMzExLWNwMzExLXdpbl9hbWQ2NApDb21waWxlcjogTVNZUzIgVUNSVDY0IE1pbkdXLXc2
  echo NCBHQ0MKQ1B5dGhvbiBoZWFkZXIgZml4OiBNU19XSU42ND0xCmZwbGxsIE1pbkdXIG1hdGggZml4
  echo OiBNX0xOMiByZXBsYWNlZCB3aXRoIGxvZygyLjApCkRMTCBidW5kbGluZzogZGVsdmV3aGVlbApS
  echo dW50aW1lIGRlcGVuZGVuY2llczogY3lzaWduYWxzPj0xLjEyLjUsIG51bXB5PT0ke1RBUkdFVF9O
  echo VU1QWV9WRVJTSU9OfQpCdWlsZCBkZXBlbmRlbmNpZXM6IGlzb2xhdGVkIHZpcnR1YWwgZW52aXJv
  echo bm1lbnQKU21va2UgdGVzdDogd2hlZWwtb25seSBpbnN0YWxsIGludG8gYSBjbGVhbiBuYXRpdmUg
  echo V2luZG93cyBDUHl0aG9uIDMuMTEgdmlydHVhbCBlbnZpcm9ubWVudApRRCBzdXBwb3J0OiBkaXNh
  echo YmxlZAoKVGhpcyB3aGVlbCBpcyBmb3IgNjQtYml0IG5hdGl2ZSBXaW5kb3dzIENQeXRob24gMy4x
  echo MSBlbnZpcm9ubWVudHMgd2l0aCB0aGUKd2luX2FtZDY0IEFCSS4gSXQgaXMgbm90IGFuIE1TWVMy
  echo LVB5dGhvbiB3aGVlbC4KRU9GX0lORk8KCnByaW50ZiAnXG5TVUNDRVNTXG5XaGVlbDogJXNcbicg
  echo IiQoY3lncGF0aCAtdyAiJE9VVF9ESVIvJChiYXNlbmFtZSAiJHJlcGFpcmVkX3doZWVsIikiKSIK
)
copy /y "%B64_FILE%" "%MSYS_ROOT%\tmp\build-fpylll-win311.b64" >nul || (echo ERROR: Could not stage the build payload.& exit /b 1)
"%MSYS_ROOT%\usr\bin\bash.exe" -lc "base64 --decode --ignore-garbage /tmp/build-fpylll-win311.b64 > /tmp/build-fpylll-win311.sh" || (echo ERROR: Could not decode the build payload.& exit /b 1)

set "FPYLLL_VERSION=%FPYLLL_VERSION%"
set "FPLLL_VERSION=%FPLLL_VERSION%"

echo Building a native CPython 3.11 Windows wheel. Full output is written to:
echo   %LOG%
"%MSYS_ROOT%\usr\bin\bash.exe" -lc "set -o pipefail; /usr/bin/bash /tmp/build-fpylll-win311.sh 2>&1 | tee /tmp/fpylll-build.log"
set "RC=%ERRORLEVEL%"
copy /y "%MSYS_ROOT%\tmp\fpylll-build.log" "%LOG%" >nul 2>nul

if not "%RC%"=="0" (
  echo.
  echo BUILD FAILED. Review: %LOG%
  exit /b %RC%
)

echo.
echo BUILD SUCCEEDED.
echo Verified cp311-cp311-win_amd64 wheel: %OUT_DIR%
exit /b 0

:download
set "DL_URL=%~1"
set "DL_OUT=%~2"
del /q "%DL_OUT%.part" 2>nul

where curl.exe >nul 2>nul
if errorlevel 1 goto download_with_bitsadmin
curl.exe --fail --location --retry 5 --retry-delay 2 --output "%DL_OUT%.part" "%DL_URL%"
if not errorlevel 1 goto download_done
del /q "%DL_OUT%.part" 2>nul

:download_with_bitsadmin
where bitsadmin.exe >nul 2>nul
if errorlevel 1 goto download_with_certutil
bitsadmin.exe /transfer FpylllMsys2Download /download /priority normal "%DL_URL%" "%DL_OUT%.part" >nul
if not errorlevel 1 goto download_done
del /q "%DL_OUT%.part" 2>nul

:download_with_certutil
certutil.exe -urlcache -split -f "%DL_URL%" "%DL_OUT%.part" >nul
if errorlevel 1 exit /b 1

:download_done
move /y "%DL_OUT%.part" "%DL_OUT%" >nul
if errorlevel 1 exit /b 1
exit /b 0

:validate_sfx
if not exist "%~1" exit /b 1
for %%I in ("%~1") do if %%~zI LSS 40000000 exit /b 1
exit /b 0
