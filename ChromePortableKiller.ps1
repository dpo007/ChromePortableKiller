<#
.SYNOPSIS
    Detects, terminates, and removes unauthorized or portable versions of Google Chrome.

.DESCRIPTION
    ChromePortableKiller.ps1 is intended for deployment as a User Logon script
    (via Group Policy). It prevents users from running personal, portable, or
    self-installed copies of Google Chrome.

    The script performs the following:
      • Detects Chrome processes not launched from approved system-level paths.
      • Terminates unauthorized Chrome processes.
      • Attempts to delete the exact chrome.exe file used by each unauthorized process.
      • Scans common user-writable locations for chrome.exe and removes them.
      • Removes per-user Chrome installations located under:
            %LOCALAPPDATA%\Google\Chrome
      • Creates a log ONLY if any action is taken.

    System-installed Chrome located under Program Files or Program Files (x86)
    is fully allowed and never modified.

.NOTES
    Script Name: ChromePortableKiller.ps1
    Version: 1.0
    Author: DPO
    Created: 2025-12-06

    Requirements:
        - PowerShell 5.1+
        - Executed as user-level logon script
        - User must have rights to delete items within their own profile
        - C:\Temp is used for logging and will be created if missing
#>

#------------------------------------------------------------
# Ensure log directory (C:\Temp)
#------------------------------------------------------------
$logDir = "C:\Temp"
if (-not (Test-Path $logDir)) {
    New-Item -Path $logDir -ItemType Directory -Force | Out-Null
}

# Log file path (only created when something happens)
$logFile    = Join-Path $logDir ("ChromePortableKiller-{0}.log" -f (Get-Date -Format "yyyyMMdd"))
$logCreated = $false

function Write-Log {
    param([string]$Message)

    if (-not $logCreated) {
        "---- ChromePortableKiller started for $env:USERNAME ----" | Out-File -FilePath $logFile -Encoding utf8
        $GLOBALS:logCreated = $true
    }

    $stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logFile -Value ("[$stamp] $Message")
}

#------------------------------------------------------------
# Allowed system-level Chrome installation paths
#------------------------------------------------------------
$allowedRoots = @()

if (Test-Path "${env:ProgramFiles}\Google\Chrome") {
    $allowedRoots += (Get-Item "${env:ProgramFiles}\Google\Chrome").FullName.TrimEnd('\')
}

if (Test-Path "${env:ProgramFiles(x86)}\Google\Chrome") {
    $allowedRoots += (Get-Item "${env:ProgramFiles(x86)}\Google\Chrome").FullName.TrimEnd('\')
}

#------------------------------------------------------------
# Kill unauthorized Chrome processes + delete their chrome.exe
#------------------------------------------------------------
try {
    $chromeProcs = Get-Process chrome -ErrorAction SilentlyContinue
} catch {
    $chromeProcs = @()
}

foreach ($proc in $chromeProcs) {
    try {
        $procPath = $proc.MainModule.FileName
    } catch {
        continue
    }

    if (-not $procPath) { continue }

    $isAllowed = $false
    foreach ($root in $allowedRoots) {
        if ($procPath.ToLower().StartsWith($root.ToLower())) {
            $isAllowed = $true
            break
        }
    }

    if (-not $isAllowed) {
        Write-Log "Terminating unauthorized Chrome process PID $($proc.Id) at '$procPath'."

        try {
            $proc.Kill()
        } catch {
            Write-Log "Failed to kill PID $($proc.Id): $($_.Exception.Message)"
        }

        # Delete the chrome.exe that was actually executed
        if (Test-Path $procPath) {
            try {
                Write-Log "Removing unauthorized Chrome executable at '$procPath'."
                Remove-Item -Path $procPath -Force
            } catch {
                Write-Log "Failed to remove '$procPath': $($_.Exception.Message)"
            }
        }
    }
}

#------------------------------------------------------------
# Remove portable chrome.exe instances from common user folders
#------------------------------------------------------------
$searchRoots = @(
    $env:LOCALAPPDATA,
    $env:APPDATA,
    "${env:USERPROFILE}\Desktop",
    "${env:USERPROFILE}\Downloads",
    "${env:USERPROFILE}\Documents"
) | Where-Object { $_ -and (Test-Path $_) }

$foundChrome = @()

foreach ($root in $searchRoots) {
    try {
        Write-Host "Searching for chrome.exe under '$root'..."
        $foundChrome += Get-ChildItem -Path $root -Filter "chrome.exe" -Recurse -ErrorAction SilentlyContinue
    } catch { }
}

foreach ($file in $foundChrome | Sort-Object FullName -Unique) {
    $fullPath  = $file.FullName
    $isAllowed = $false

    foreach ($root in $allowedRoots) {
        if ($fullPath.ToLower().StartsWith($root.ToLower())) {
            $isAllowed = $true
            break
        }
    }

    if (-not $isAllowed -and (Test-Path $fullPath)) {
        Write-Log "Removing unauthorized chrome.exe at '$fullPath'."
        try {
            Remove-Item -Path $fullPath -Force
        } catch {
            Write-Log "Failed to remove '$fullPath': $($_.Exception.Message)"
        }
    }
}

#------------------------------------------------------------
# Remove per-user Chrome installation folder
#------------------------------------------------------------
$userChromeDir = "${env:LOCALAPPDATA}\Google\Chrome"

if (Test-Path $userChromeDir) {
    $isAllowed = $false

    foreach ($root in $allowedRoots) {
        if ($userChromeDir.ToLower().StartsWith($root.ToLower())) {
            $isAllowed = $true
            break
        }
    }

    if (-not $isAllowed) {
        Write-Log "Removing per-user Chrome directory '$userChromeDir'."
        try {
            Remove-Item -Path $userChromeDir -Recurse -Force
        } catch {
            Write-Log "Failed to remove '$userChromeDir': $($_.Exception.Message)"
        }
    }
}

#------------------------------------------------------------
# Cleanup: remove empty log if nothing actually happened
#------------------------------------------------------------
if (-not $logCreated) {
    if (Test-Path $logFile) {
        $logItem = Get-Item $logFile
        if ($logItem.Length -eq 0) {
            Remove-Item $logFile -Force
        }
    }
}
