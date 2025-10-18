# Get startup folder path
$startupFolder = [Environment]::GetFolderPath("Startup")

# Define apps with their common paths
$apps = @{
    "Chrome" = @(
        "${env:ProgramFiles}\Google\Chrome\Application\chrome.exe",
        "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe"
    )
    "Notion" = @(
        "${env:LOCALAPPDATA}\Programs\Notion\Notion.exe"
    )
    "Sublime Text 3" = @(
        "${env:ProgramFiles}\Sublime Text 3\sublime_text.exe",
        "${env:ProgramFiles(x86)}\Sublime Text 3\sublime_text.exe"
    )
    "Windows Terminal" = @(
        "${env:LOCALAPPDATA}\Microsoft\WindowsApps\wt.exe"
    )
    "VNC Viewer" = @(
        "${env:ProgramFiles}\RealVNC\VNC Viewer\vncviewer.exe",
        "${env:ProgramFiles(x86)}\RealVNC\VNC Viewer\vncviewer.exe"
        "${env:ProgramFiles}\uvnc bvba\UltraVNC\vncviewer.exe"
    )
}

foreach ($appName in $apps.Keys) {
    $found = $false
    foreach ($path in $apps[$appName]) {
        if (Test-Path $path) {
            # Create shortcut in startup folder
            $shortcutPath = "$startupFolder\$appName.lnk"
            # Use WScript.Shell to create shortcut
            $WshShell = New-Object -comObject WScript.Shell
            $Shortcut = $WshShell.CreateShortcut($shortcutPath)
            $Shortcut.TargetPath = $path
            $Shortcut.Save()
            Write-Host "Added $appName to startup" -ForegroundColor Green
            $found = $true
            break
        }
    }
    if (!$found) {
        Write-Host "- $appName not found, skipping" -ForegroundColor Yellow
    }
}