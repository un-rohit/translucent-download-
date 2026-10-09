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

    # 8. Add to User Environment PATH
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

    # 9. Launch Application
    Write-Host ""
    Write-Host "======================================================================" -ForegroundColor Green
    Write-Host " [✓] Translucent installed successfully!" -ForegroundColor Green
    Write-Host "     Location: $TargetExe" -ForegroundColor White
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
