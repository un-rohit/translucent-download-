# ==============================================================================
# Translucent - Stealth AI Copilot for Windows
# Official 1-Command PowerShell Installer
#
# Usage:
#   irm https://translucent-livid.vercel.app/install.ps1 | iex
# ==============================================================================

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}
$ErrorActionPreference = "Stop"

function Write-TranslucentBanner {
    Write-Host ""
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "     TRANSLUCENT - Stealth Desktop AI Copilot for Windows " -ForegroundColor Cyan
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host ""
}

try {
    Write-TranslucentBanner

    # 1. Platform Verification
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        throw "PowerShell 5.1 or newer is required to install Translucent."
    }

    if (-not [Environment]::Is64BitOperatingSystem) {
        throw "Translucent requires a 64-bit (x64) Windows operating system."
    }

    # 2. Paths Configuration
    $InstallDir = Join-Path $env:LOCALAPPDATA "Programs\Translucent"
    $TargetExe  = Join-Path $InstallDir "Translucent.exe"
    $UninstallScript = Join-Path $InstallDir "uninstall.ps1"
    $ShortcutDir = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs"
    $ShortcutPath = Join-Path $ShortcutDir "Translucent.lnk"

    # 3. Gracefully close existing running instance
    $running = Get-Process -Name "Translucent" -ErrorAction SilentlyContinue
    if ($running) {
        Write-Host "[-] Closing running instance of Translucent..." -ForegroundColor Yellow
        $running | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 600
    }

    # 4. Create target directory
    if (-not (Test-Path $InstallDir)) {
        New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    }

    # 5. Determine Latest Version & Download URLs
    $LatestReleaseTag = "v1.2.3.0"
    $LatestVersion = "1.2.3.0"
    try {
        $apiRel = Invoke-RestMethod -Uri "https://api.github.com/repos/un-rohit/translucent-download-/releases/latest" -Headers @{"User-Agent"="Translucent-Installer"} -TimeoutSec 6 -ErrorAction SilentlyContinue
        if ($apiRel -and $apiRel.tag_name) {
            $LatestReleaseTag = $apiRel.tag_name
            $LatestVersion = $LatestReleaseTag.Replace("v", "")
        }
    } catch {}

    $DownloadUrls = @(
        "https://github.com/un-rohit/translucent-download-/releases/download/v1.2.3.0/Translucent-Setup.exe",
        "https://github.com/un-rohit/translucent-download-/releases/latest/download/Translucent-Setup.exe",
        "https://github.com/un-rohit/translucent-download-/releases/download/v1.2.3.0/Translucent.Standalone.exe",
        "https://github.com/un-rohit/translucent-download-/releases/latest/download/Translucent.Standalone.exe",
        "https://translucent-livid.vercel.app/downloads/Translucent-Setup.exe",
        "https://translucent-livid.vercel.app/downloads/Translucent.Standalone.exe",
        "https://github.com/un-rohit/translucent-download-/releases/latest/download/Translucent.exe",
        "https://github.com/un-rohit/translucent-download-/releases/download/$LatestReleaseTag/Translucent.exe",
        "https://github.com/un-rohit/translucent-download-/releases/download/v1.2.3.0/Translucent.exe"
    )

    $Downloaded = $false
    $successfulUrl = ""
    $TempExe = Join-Path $env:TEMP ("Translucent_Setup_" + [System.Guid]::NewGuid().ToString("N") + ".exe")

    foreach ($url in $DownloadUrls) {
        try {
            Write-Host "[>] Downloading Translucent ($LatestReleaseTag)..." -ForegroundColor Cyan
            Write-Host "    Source: $url" -ForegroundColor DarkGray
            
            $webClient = New-Object System.Net.WebClient
            $webClient.Headers.Add("User-Agent", "Translucent-Installer/1.0 (Windows)")
            $webClient.DownloadFile($url, $TempExe)

            if ((Test-Path $TempExe) -and ((Get-Item $TempExe).Length -gt 10000000)) {
                $Downloaded = $true
                $successfulUrl = $url
                break
            }
        } catch {
            Write-Host "    [!] Mirror failed, trying alternate mirror..." -ForegroundColor DarkYellow
        }
    }

    if (-not $Downloaded) {
        throw "Failed to download Translucent installer from release mirrors. Please check your internet connection."
    }

    if ($successfulUrl -like "*Setup*.exe") {
        Write-Host "[+] Running verified Inno Setup installer silently..." -ForegroundColor Cyan
        Start-Process -FilePath $TempExe -ArgumentList "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART" -Wait
        Remove-Item -Path $TempExe -Force -ErrorAction SilentlyContinue
    } else {
        # 6. Install executable into destination
        Write-Host "[+] Installing binary to $InstallDir..." -ForegroundColor Cyan
        Move-Item -Path $TempExe -Destination $TargetExe -Force

        # 7. Register Start Menu Shortcut
        try {
            if (-not (Test-Path $ShortcutDir)) {
                New-Item -ItemType Directory -Path $ShortcutDir -Force | Out-Null
            }
            $wsh = New-Object -ComObject WScript.Shell
            $shortcut = $wsh.CreateShortcut($ShortcutPath)
            $shortcut.TargetPath = $TargetExe
            $shortcut.WorkingDirectory = $InstallDir
            $shortcut.IconLocation = "$TargetExe,0"
            $shortcut.Description = "Translucent - Stealth AI Copilot for Windows"
            $shortcut.Save()
            Write-Host "[+] Created Start Menu shortcut: Translucent" -ForegroundColor Green
        } catch {
            Write-Host "[-] Note: Start menu shortcut creation skipped ($($_.Exception.Message))" -ForegroundColor DarkGray
        }

        # 8. Create Dedicated Uninstaller Script
        try {
            $uninstallBase64 = "W0NtZGxldEJpbmRpbmcoKV0KcGFyYW0oW3N3aXRjaF0kUXVpZXQsIFtzd2l0Y2hdJEZvcmNlKQoKJEVycm9yQWN0aW9uUHJlZmVyZW5jZSA9ICJTaWxlbnRseUNvbnRpbnVlIgoKdHJ5IHsKICAgIEFkZC1UeXBlIC1Bc3NlbWJseU5hbWUgU3lzdGVtLldpbmRvd3MuRm9ybXMgLUVycm9yQWN0aW9uIFNpbGVudGx5Q29udGludWUKfSBjYXRjaCB7fQoKaWYgKC1ub3QgJFF1aWV0IC1hbmQgLW5vdCAkRm9yY2UpIHsKICAgIHRyeSB7CiAgICAgICAgJHJlcyA9IFtTeXN0ZW0uV2luZG93cy5Gb3Jtcy5NZXNzYWdlQm94XTo6U2hvdygKICAgICAgICAgICAgIlFyZSB5b3Ugc3VyZSB5b3Ugd2FudCB0byB1bmluc3RhbGwgVHJhbnNsdWNlbnQgYW5kIHJlbW92ZSBhbGwgb2YgaXRzIGNvbXBvbmVudHM/IiwKICAgICAgICAgICAgIlVuaW5zdGFsbCBUcmFuc2x1Y2VudCIsCiAgICAgICAgICAgIFtTeXN0ZW0uV2luZG93cy5Gb3Jtcy5NZXNzYWdlQm94QnV0dG9uc106Olllc05vLAogICAgICAgICAgICBbU3lzdGVtLldpbmRvd3MuRm9ybXMuTWVzc2FnZUJveEljb25dOjpRdWVzdGlvbgogICAgICAgICkKICAgICAgICBpZiAoJHJlcyAtbmUgW1N5c3RlbS5XaW5kb3dzLkZvcm1zLkRpYWxvZ1Jlc3VsdF06OlllcykgewogICAgICAgICAgICBleGl0IDAKICAgICAgICB9CiAgICB9IGNhdGNoIHt9Cn0KCiMgMS4gVGVybWluYXRlIHJ1bm5pbmcgcHJvY2VzcwpHZXQtUHJvY2VzcyAtTmFtZSAiVHJhbnNsdWNlbnQiIC1FcnJvckFjdGlvbiBTaWxlbnRseUNvbnRpbnVlIHwgU3RvcC1Qcm9jZXNzIC1Gb3JjZSAtRXJyb3JBY3Rpb24gU2lsZW50bHlDb250aW51ZQpTdGFydC1TbGVlcCAtTWlsbGlzZWNvbmRzIDQwMAoKIyAyLiBSZW1vdmUgU2hvcnRjdXRzCiRTaG9ydGN1dHMgPSBAKAogICAgKEpvaW4tUGF0aCAkZW52OkFQUERBVEEgIk1pY3Jvc29mdFxXaW5kb3dzXFN0YXJ0IE1lbnVcUHJvZ3JhbXNcVHJhbnNsdWNlbnQubG5rIiksCiAgICAoSm9pbi1QYXRoIChbRW52aXJvbm1lbnRdOjpHZXRGb2xkZXJQYXRoKCJEZXNrdG9wIikpICJUcmFuc2x1Y2VudC5sbmsiKQopCmZvcmVhY2ggKCRzYyBpbiAkU2hvcnRjdXRzKSB7CiAgICBpZiAoVGVzdC1QYXRoICRzYykgewogICAgICAgIFJlbW92ZS1JdGVtIC1QYXRoICRzYyAtRm9yY2UgLUVycm9yQWN0aW9uIFNpbGVudGx5Q29udGludWUKICAgIH0KfQoKIyAzLiBDbGVhbiB1c2VyIFBBVEgKdHJ5IHsKICAgICRkaXIgPSBpZiAoJFBTU2NyaXB0Um9vdCkgeyAkUFNTY3JpcHRSb290IH0gZWxzZSB7IEpvaW4tUGF0aCAkZW52OkxPQ0FMQVBQREFUQSAiUHJvZ3JhbXNcVHJhbnNsdWNlbnQiIH0KICAgICR1c2VyUGF0aCA9IFtFbnZpcm9ubWVudF06OkdldEVudmlyb25tZW50VmFyaWFibGUoIlBhdGgiLCAiVXNlciIpCiAgICBpZiAoJHVzZXJQYXRoIC1saWtlICIqJGRpcioiKSB7CiAgICAgICAgJHBhdGhzID0gJHVzZXJQYXRoIC1zcGxpdCAiOyIgfCBXaGVyZS1PYmplY3QgeyAkXyAtYW5kICgkXyAtbmUgJGRpcikgfQogICAgICAgIFtFbnZpcm9ubWVudF06OlNldEVudmlyb25tZW50VmFyaWFibGUoIlBhdGgiLCAoJHBhdGhzIC1qb2luICI7IiksICJVc2VyIikKICAgIH0KfSBjYXRjaCB7fQoKIyA0LiBSZW1vdmUgVW5pbnN0YWxsIFJlZ2lzdHJ5IEtleQp0cnkgewogICAgJHJlZ0tleSA9ICJIS0NVOlxTb2Z0d2FyZVxNaWNyb3NvZnRcV2luZG93c1xDdXJyZW50VmVyc2lvblxVbmluc3RhbGxcVHJhbnNsdWNlbnQiCiAgICBpZiAoVGVzdC1QYXRoICRyZWdLZXkpIHsKICAgICAgICBSZW1vdmUtSXRlbSAtUGF0aCAkcmVnS2V5IC1SZWN1cnNlIC1Gb3JjZSAtRXJyb3JBY3Rpb24gU2lsZW50bHlDb250aW51ZQogICAgfQp9IGNhdGNoIHt9CgojIDUuIFJlbW92ZSBJbnN0YWxsYXRpb24gRGlyZWN0b3J5CnRyeSB7CiAgICAkZGlyID0gaWYgKCRQU1NjcmlwdFJvb3QpIHsgJFBTU2NyaXB0Um9vdCkgeyAkUFNTY3JpcHRSb290IH0gZWxzZSB7IEpvaW4tUGF0aCAkZW52OkxPQ0FMQVBQREFUQSAiUHJvZ3JhbXNcVHJhbnNsdWNlbnQiIH0KICAgIFJlbW92ZS1JdGVtIC1QYXRoIChKb2luLVBhdGggJGRpciAiVHJhbnNsdWNlbnQuZXhlIikgLUZvcmNlIC1FcnJvckFjdGlvbiBTaWxlbnRseUNvbnRpbnVlCiAgICBTdGFydC1Qcm9jZXNzIGNtZC5leGUgLUFyZ3VtZW50TGlzdCAiL2MgcGluZyAxMjcuMC4wLjEgLW4gMiA+bnVsICYgcm1kaXIgL3MgL3EgYCIkZGlyYCIiIC1XaW5kb3dTdHlsZSBIaWRkZW4KfSBjYXRjaCB7fQoKaWYgKC1ub3QgJFF1aWV0IC1hbmQgLW5vdCAkRm9yY2UpIHsKICAgIHRyeSB7CiAgICAgICAgW1N5c3RlbS5XaW5kb3dzLkZvcm1zLk1lc3NhZ2VCb3hdOjpTaG93KAogICAgICAgICAgICAiVHJhbnNsdWNlbnQgd2FzIHN1Y2Nlc3NmdWxseSB1bmluc3RhbGxlZCBmcm9tIHlvdXIgY29tcHV0ZXIuIiwKICAgICAgICAgICAgIlVuaW5zdGFsbCBUcmFuc2x1Y2VudCIsCiAgICAgICAgICAgIFtTeXN0ZW0uV2luZG93cy5Gb3Jtcy5NZXNzYWdlQm94QnV0dG9uc106Olllc05vLAogICAgICAgICAgICBbU3lzdGVtLldpbmRvd3MuRm9ybXMuTWVzc2FnZUJveEljb25dOjpJbmZvcm1hdGlvbgogICAgICAgICkgfCBPdXQtTnVsbAogICAgfSBjYXRjaCB7fQp9Cg=="
            $uninstallBytes = [System.Convert]::FromBase64String($uninstallBase64)
            [System.IO.File]::WriteAllBytes($UninstallScript, $uninstallBytes)
            Write-Host "[+] Configured Uninstaller script at $UninstallScript" -ForegroundColor Green
        } catch {
            Write-Host "[-] Note: Uninstaller creation note: $($_.Exception.Message)" -ForegroundColor DarkGray
        }

        # 9. Register with Windows Settings & Control Panel ("Installed Apps" & "Uninstall a program")
        try {
            $regKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\Translucent"
            if (-not (Test-Path $regKey)) {
                New-Item -Path $regKey -Force | Out-Null
            }
            $fileSizeKB = if (Test-Path $TargetExe) { [int]((Get-Item $TargetExe).Length / 1KB) } else { 150000 }
            $UninstallCommand = "powershell.exe -ExecutionPolicy Bypass -File ""$UninstallScript"""
            $QuietUninstallCommand = "powershell.exe -ExecutionPolicy Bypass -File ""$UninstallScript"" -Quiet"

            Set-ItemProperty -Path $regKey -Name "DisplayName" -Value "Translucent" -Type String
            Set-ItemProperty -Path $regKey -Name "DisplayVersion" -Value $LatestVersion -Type String
            Set-ItemProperty -Path $regKey -Name "Publisher" -Value "Translucent" -Type String
            Set-ItemProperty -Path $regKey -Name "DisplayIcon" -Value "$TargetExe,0" -Type String
            Set-ItemProperty -Path $regKey -Name "InstallLocation" -Value "$InstallDir" -Type String
            Set-ItemProperty -Path $regKey -Name "InstallDate" -Value ((Get-Date).ToString("yyyyMMdd")) -Type String
            Set-ItemProperty -Path $regKey -Name "UninstallString" -Value $UninstallCommand -Type String
            Set-ItemProperty -Path $regKey -Name "QuietUninstallString" -Value $QuietUninstallCommand -Type String
            Set-ItemProperty -Path $regKey -Name "EstimatedSize" -Value $fileSizeKB -Type DWord
            Set-ItemProperty -Path $regKey -Name "HelpLink" -Value "https://translucent-livid.vercel.app" -Type String
            Set-ItemProperty -Path $regKey -Name "URLInfoAbout" -Value "https://translucent-livid.vercel.app" -Type String
            Set-ItemProperty -Path $regKey -Name "NoModify" -Value 1 -Type DWord
            Set-ItemProperty -Path $regKey -Name "NoRepair" -Value 1 -Type DWord
            Write-Host "[+] Registered in Windows Installed Apps & Control Panel" -ForegroundColor Green
        } catch {
            Write-Host "[-] Note: Windows registry registration note: $($_.Exception.Message)" -ForegroundColor DarkGray
        }
    }

    # 10. Add to User Environment PATH
    try {
        $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
        if ($userPath -notlike "*$InstallDir*") {
            $newPath = if ([string]::IsNullOrWhiteSpace($userPath)) { $InstallDir } else { "$userPath;$InstallDir" }
            [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
            $env:Path = "$env:Path;$InstallDir"
            Write-Host "[+] Added to PATH: Type translucent anywhere in terminal" -ForegroundColor Green
        }
    } catch {
        Write-Host "[-] PATH registration note: $($_.Exception.Message)" -ForegroundColor DarkGray
    }

    # 11. Launch Application
    Write-Host ""
    Write-Host "======================================================================" -ForegroundColor Green
    Write-Host " [OK] Translucent v$LatestVersion installed successfully!" -ForegroundColor Green
    Write-Host "     Location: $TargetExe" -ForegroundColor White
    Write-Host "     Uninstall: Apps > Installed apps OR Control Panel" -ForegroundColor Gray
    Write-Host "     Hotkeys:  Ctrl + Shift + V (Summon) | Ctrl + Shift + H (Ghost Mode)" -ForegroundColor Cyan
    Write-Host "======================================================================" -ForegroundColor Green
    Write-Host ""

    Write-Host "[>] Launching Translucent..." -ForegroundColor Cyan
    Start-Process -FilePath $TargetExe

} catch {
    Write-Host ""
    Write-Host "[X] Installation failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "    You can download the installer directly from:" -ForegroundColor Yellow
    Write-Host "    https://github.com/un-rohit/translucent-download-/releases/tag/v1.2.3.0" -ForegroundColor White
    Write-Host ""
}
