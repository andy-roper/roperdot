Write-Host "Applying Windows configuration changes..." -ForegroundColor Green

# Enable Telnet Client
Write-Host "Enabling Telnet Client..." -ForegroundColor Yellow
try {
    # Use PowerShell cmdlet instead of dism for better reliability
    Enable-WindowsOptionalFeature -Online -FeatureName TelnetClient -All -NoRestart | Out-Null
    Write-Host "Telnet Client enabled - will be available after next reboot" -ForegroundColor Green
} catch {
    Write-Host "Failed to enable Telnet Client: $($_.Exception.Message)" -ForegroundColor Red
}

# Configure Windows Search (Local Only)
Write-Host "Configuring Windows Search for local-only..." -ForegroundColor Yellow
try {
    # User-level settings
    if (!(Test-Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search")) {
        New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Force | Out-Null
    }
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "BingSearchEnabled" -Value 0 -Type DWord
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "CortanaConsent" -Value 0 -Type DWord
    
    # System-level policy (may require admin)
    if (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search")) {
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Force | Out-Null
    }
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "ConnectedSearchUseWeb" -Value 0 -Type DWord
    
    Write-Host "Windows Search configured for local-only" -ForegroundColor Green
} catch {
    Write-Host "Failed to configure Windows Search: $($_.Exception.Message)" -ForegroundColor Red
}

# Revert to Windows 10 style Explorer
Write-Host "Reverting to Windows 10 Explorer style..." -ForegroundColor Yellow
try {
    # Create the registry paths if they don't exist and set empty default values
    $path1 = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"
    $path2 = "HKCU:\Software\Classes\CLSID\{d93ed569-3b3e-4bff-8355-3c44f6a52bb5}\InprocServer32"
    
    if (!(Test-Path $path1)) {
        New-Item -Path $path1 -Force | Out-Null
    }
    Set-ItemProperty -Path $path1 -Name "(Default)" -Value "" -Type String
    
    if (!(Test-Path $path2)) {
        New-Item -Path $path2 -Force | Out-Null
    }
    Set-ItemProperty -Path $path2 -Name "(Default)" -Value "" -Type String
    
    Write-Host "Explorer reverted to Windows 10 style" -ForegroundColor Green
    Write-Host "  Note: You may need to restart Explorer or reboot for changes to take effect" -ForegroundColor Cyan
} catch {
    Write-Host "Failed to revert Explorer style: $($_.Exception.Message)" -ForegroundColor Red
}

# Disable Windows tracking/telemetry
Write-Host "Disabling Windows telemetry..." -ForegroundColor Yellow
try {
    if (!(Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection")) {
        New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Force | Out-Null
    }
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "AllowTelemetry" -Value 0 -Type DWord
    Write-Host "Windows telemetry disabled" -ForegroundColor Green
} catch {
    Write-Host "Failed to disable telemetry (may require admin): $($_.Exception.Message)" -ForegroundColor Red
}

# Show file extensions and hidden files
Write-Host "Configuring Explorer view options..." -ForegroundColor Yellow
try {
    # These paths usually exist, but check to be safe
    if (!(Test-Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced")) {
        New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Force | Out-Null
    }
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0 -Type DWord
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value 1 -Type DWord
    Write-Host "File extensions and hidden files now visible" -ForegroundColor Green
} catch {
    Write-Host "Failed to configure Explorer view: $($_.Exception.Message)" -ForegroundColor Red
}

# Disable Cortana search box
Write-Host "Disabling Cortana search box..." -ForegroundColor Yellow
try {
    # This path usually exists from earlier search configuration
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -Value 0 -Type DWord
    Write-Host "Cortana search box disabled" -ForegroundColor Green
} catch {
    Write-Host "Failed to disable Cortana: $($_.Exception.Message)" -ForegroundColor Red
}

# Enable dark theme
Write-Host "Enabling dark theme..." -ForegroundColor Yellow
try {
    if (!(Test-Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize")) {
        New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Force | Out-Null
    }
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -Value 0 -Type DWord
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "SystemUsesLightTheme" -Value 0 -Type DWord
    Write-Host "Dark theme enabled" -ForegroundColor Green
} catch {
    Write-Host "Failed to enable dark theme: $($_.Exception.Message)" -ForegroundColor Red
}

# Disable startup delay
Write-Host "Disabling startup delay..." -ForegroundColor Yellow
try {
    if (!(Test-Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize")) {
        New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" -Force | Out-Null
    }
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" -Name "StartupDelayInMSec" -Value 0 -Type DWord
    Write-Host "Startup delay disabled" -ForegroundColor Green
} catch {
    Write-Host "Failed to disable startup delay: $($_.Exception.Message)" -ForegroundColor Red
}

# Disable Windows Update automatic restart
Write-Host "Disabling automatic Windows Update restarts..." -ForegroundColor Yellow
try {
    if (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU")) {
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Force | Out-Null
    }
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoRebootWithLoggedOnUsers" -Value 1 -Type DWord
    Write-Host "Automatic Windows Update restarts disabled" -ForegroundColor Green
} catch {
    Write-Host "Failed to disable auto-restart (may require admin): $($_.Exception.Message)" -ForegroundColor Red
}

# Set Chrome as default browser (if present)
Write-Host "Setting Chrome as default browser..." -ForegroundColor Yellow
try {
    $chromePaths = @(
        "${env:ProgramFiles}\Google\Chrome\Application\chrome.exe",
        "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe"
    )
    
    $chromeFound = $false
    foreach ($path in $chromePaths) {
        if (Test-Path $path) {
            $chromeFound = $true
            $success = $false
            
            Write-Host "Found Chrome at: $path" -ForegroundColor Cyan
            
            # Method 1: Registry approach for HTTP/HTTPS protocols
            try {
                $chromeKey = "ChromeHTML"
                
                # Set Chrome as handler for http and https
                Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\http\UserChoice" -Name "ProgId" -Value $chromeKey -ErrorAction SilentlyContinue
                Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\https\UserChoice" -Name "ProgId" -Value $chromeKey -ErrorAction SilentlyContinue
                
                Write-Host "Chrome registry associations updated" -ForegroundColor Green
                $success = $true
            } catch {
                Write-Host "Registry method failed, trying alternative..." -ForegroundColor Yellow
            }
            
            # Method 2: Try the Chrome command line flag if registry failed
            if (!$success) {
                try {
                    Start-Process -FilePath $path -ArgumentList "--make-default-browser" -WindowStyle Hidden -Wait
                    Write-Host "Chrome --make-default-browser executed" -ForegroundColor Green
                    $success = $true
                } catch {
                    Write-Host "Chrome command line method failed" -ForegroundColor Yellow
                }
            }
            
            # Method 3: Open Windows Settings only if other methods failed
            if (!$success) {
                Write-Host "Automated methods failed. Opening Windows Settings for manual configuration..." -ForegroundColor Cyan
                Write-Host "  -> Please manually set Chrome as default browser in the settings that opened" -ForegroundColor Yellow
                Start-Process "ms-settings:defaultapps"
            }
            
            break
        }
    }
    
    if (!$chromeFound) {
        Write-Host "Chrome not found, skipping default browser setting" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Failed to set Chrome as default browser: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "Restarting Explorer to apply changes..." -ForegroundColor Yellow
try {
    Stop-Process -Name explorer -Force
    Start-Sleep 2
    Write-Host "Explorer restarted" -ForegroundColor Green
} catch {
    Write-Host "Note: You may need to restart Explorer manually for all changes to take effect" -ForegroundColor Yellow
}