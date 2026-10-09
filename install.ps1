# ==============================================================================
# Translucent — Stealth AI Copilot for Windows
# Official 1-Command PowerShell Installer
#
# Usage:
#   irm https://raw.githubusercontent.com/un-rohit/translucent-download-/main/install.ps1 | iex
# ==============================================================================

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
$ErrorActionPreference = "Stop"

function Write-TranslucentBanner {
    Write-Host ""
    Write-Host "   ████████╗██████╗  █████╗ ███╗   ██╗███████╗██╗     ██╗   ██╗ ██████╗███████╗███╗   ██╗████████╗" -ForegroundColor Cyan
    Write-Host "   ╚══██╔══╝██╔══██╗██╔══██╗████╗  ██║██╔════╝██║     ██║   ██║██╔════╝██╔════╝████╗  ██║╚══██╔══╝" -ForegroundColor Cyan
    Write-Host "      ██║   ██████╔╝███████║██╔██╗ ██║███████╗██║     ██║   ██║██║     █████╗  ██╔██╗ ██║   ██║   " -ForegroundColor Magenta
    Write-Host "      ██║   ██╔══██╗██╔══██║██║╚██╗██║╚════██║██║     ██║   ██║██║     ██╔══╝  ██║╚██╗██║   ██║   " -ForegroundColor Magenta
    Write-Host "      ██║   ██║  ██║██║  ██║██║ ╚████║███████║███████╗╚██████╔╝╚██████╗███████╗██║ ╚████║   ██║   " -ForegroundColor Blue
    Write-Host "      ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝╚══════╝ ╚═════╝  ╚═════╝╚══════╝╚═╝  ╚═══╝   ╚═╝   " -ForegroundColor Blue
    Write-Host "                            The Stealth AI Copilot for Windows                                  " -ForegroundColor Gray
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

    # 5. Download URLs (Primary GitHub release with reliable fallbacks)
    $DownloadUrls = @(
        "https://github.com/un-rohit/translucent-download-/releases/download/v1.0.12/Translucent.exe",
        "https://github.com/un-rohit/translucent-download-/releases/latest/download/Translucent.exe"
    )

    $Downloaded = $false
    $TempExe = Join-Path $env:TEMP ("Translucent_Setup_" + [System.Guid]::NewGuid().ToString("N") + ".exe")

    foreach ($url in $DownloadUrls) {
        try {
            Write-Host "[>] Downloading Translucent from GitHub Releases..." -ForegroundColor Cyan
            Write-Host "    Source: $url" -ForegroundColor DarkGray
            
            # Use WebClient for clean download speed and progress reporting
            $webClient = New-Object System.Net.WebClient
            $webClient.Headers.Add("User-Agent", "Translucent-Installer/1.0 (Windows)")
            $webClient.DownloadFile($url, $TempExe)

            if ((Test-Path $TempExe) -and ((Get-Item $TempExe).Length -gt 10000000)) {
                $Downloaded = $true
                break
            }
        } catch {
            Write-Host "    [!] Mirror failed, trying alternate mirror..." -ForegroundColor DarkYellow
        }
    }

    if (-not $Downloaded) {
        throw "Failed to download Translucent.exe from release mirrors. Please check your internet connection."
    }

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
        $shortcut.Description = "Translucent — Stealth AI Copilot for Windows"
        $shortcut.Save()
        Write-Host "[+] Created Start Menu shortcut: Translucent" -ForegroundColor Green
    } catch {
        Write-Host "[-] Note: Start menu shortcut creation skipped ($($_.Exception.Message))" -ForegroundColor DarkGray
    }

    # 8. Create Dedicated Uninstaller Script
    try {
        $uninstallCode = @'
[CmdletBinding()]
param([switch]$Quiet, [switch]$Force)

$ErrorActionPreference = "SilentlyContinue"

try {
    Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
} catch {}

if (-not $Quiet -and -not $Force) {
    try {
        $res = [System.Windows.Forms.MessageBox]::Show(
            "Are you sure you want to uninstall Translucent and remove all of its components?",
            "Uninstall Translucent",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Question
        )
        if ($res -ne [System.Windows.Forms.DialogResult]::Yes) {
            exit 0
        }
    } catch {}
}

# 1. Terminate running process
Get-Process -Name "Translucent" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 400

# 2. Remove Shortcuts
$Shortcuts = @(
    (Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\Translucent.lnk"),
    (Join-Path ([Environment]::GetFolderPath("Desktop")) "Translucent.lnk")
)
foreach ($sc in $Shortcuts) {
    if (Test-Path $sc) {
        Remove-Item -Path $sc -Force -ErrorAction SilentlyContinue
    }
}

# 3. Clean user PATH
try {
    $dir = if ($PSScriptRoot) { $PSScriptRoot } else { Join-Path $env:LOCALAPPDATA "Programs\Translucent" }
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($userPath -like "*$dir*") {
        $paths = $userPath -split ";" | Where-Object { $_ -and ($_ -ne $dir) }
        [Environment]::SetEnvironmentVariable("Path", ($paths -join ";"), "User")
    }
} catch {}

# 4. Remove Uninstall Registry Key
try {
    $regKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\Translucent"
    if (Test-Path $regKey) {
        Remove-Item -Path $regKey -Recurse -Force -ErrorAction SilentlyContinue
    }
} catch {}

# 5. Remove Installation Directory
try {
    $dir = if ($PSScriptRoot) { $PSScriptRoot } else { Join-Path $env:LOCALAPPDATA "Programs\Translucent" }
    Remove-Item -Path (Join-Path $dir "Translucent.exe") -Force -ErrorAction SilentlyContinue
    Start-Process cmd.exe -ArgumentList "/c ping 127.0.0.1 -n 2 >nul & rmdir /s /q `"$dir`"" -WindowStyle Hidden
} catch {}

if (-not $Quiet -and -not $Force) {
    try {
        [System.Windows.Forms.MessageBox]::Show(
            "Translucent was successfully uninstalled from your computer.",
            "Uninstall Translucent",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        ) | Out-Null
    } catch {}
}
'@
        [System.IO.File]::WriteAllText($UninstallScript, $uninstallCode, [System.Text.Encoding]::UTF8)
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
        $fileSizeKB = if (Test-Path $TargetExe) { [int]((Get-Item $TargetExe).Length / 1KB) } else { 77000 }
        $UninstallCommand = "powershell.exe -ExecutionPolicy Bypass -File `"$UninstallScript`""
        $QuietUninstallCommand = "powershell.exe -ExecutionPolicy Bypass -File `"$UninstallScript`" -Quiet"

        Set-ItemProperty -Path $regKey -Name "DisplayName" -Value "Translucent" -Type String
        Set-ItemProperty -Path $regKey -Name "DisplayVersion" -Value "1.0.12" -Type String
        Set-ItemProperty -Path $regKey -Name "Publisher" -Value "Translucent" -Type String
        Set-ItemProperty -Path $regKey -Name "DisplayIcon" -Value "$TargetExe,0" -Type String
        Set-ItemProperty -Path $regKey -Name "InstallLocation" -Value "$InstallDir" -Type String
        Set-ItemProperty -Path $regKey -Name "InstallDate" -Value (Get-Date -Format 'yyyyMMdd') -Type String
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

    # 10. Add to User Environment PATH
    try {
        $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
        if ($userPath -notlike "*$InstallDir*") {
            $newPath = if ([string]::IsNullOrWhiteSpace($userPath)) { $InstallDir } else { "$userPath;$InstallDir" }
            [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
            $env:Path = "$env:Path;$InstallDir"
            Write-Host "[+] Added to PATH: Type 'translucent' anywhere in terminal" -ForegroundColor Green
        }
    } catch {
        Write-Host "[-] PATH registration note: $($_.Exception.Message)" -ForegroundColor DarkGray
    }

    # 11. Launch Application
    Write-Host ""
    Write-Host "======================================================================" -ForegroundColor Green
    Write-Host " [✓] Translucent installed successfully!" -ForegroundColor Green
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
    Write-Host "    You can download the standalone executable directly from:" -ForegroundColor Yellow
    Write-Host "    https://github.com/un-rohit/translucent-download-/releases/tag/v1.0.12" -ForegroundColor White
    Write-Host ""
}
