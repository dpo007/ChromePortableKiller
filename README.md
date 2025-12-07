# ChromePortableKiller

A PowerShell script that detects, terminates, and removes unauthorized or portable versions of Google Chrome from user systems while preserving system-level installations.

## Overview

ChromePortableKiller is designed for deployment as a User Logon script via Group Policy in enterprise environments. It helps IT administrators enforce browser policies by preventing users from running personal, portable, or self-installed copies of Google Chrome.

## Features

- ✅ **Process Detection**: Identifies Chrome processes not launched from approved system-level paths
- 🛑 **Automatic Termination**: Kills unauthorized Chrome processes
- 🗑️ **File Removal**: Deletes unauthorized chrome.exe files and installations
- 📁 **Deep Scanning**: Searches common user-writable locations for portable Chrome instances
- 🔒 **System Protection**: Never modifies system-installed Chrome in Program Files
- 📝 **Action Logging**: Creates logs only when actions are taken

## Parameters

- `DelayMinutes` (`int`, default: `10`)
  - Number of minutes to wait before the script begins scanning for processes. Ignored unless `-EnableDelay` is specified.

- `EnableDelay` (`switch`)
  - When present, the script waits `DelayMinutes` before starting enforcement. This gives users time to launch their portable Chrome instances after logon, increasing the chance of detecting and terminating unauthorized Chrome processes.

## How It Works

The script performs the following operations:

1. **Identifies Allowed Installations**: Recognizes system-level Chrome installations in:
   - `%ProgramFiles%\Google\Chrome`
   - `%ProgramFiles(x86)%\Google\Chrome`

2. **Terminates Unauthorized Processes**: Kills Chrome processes running from unauthorized locations

3. **Removes Unauthorized Executables**: Deletes chrome.exe files from:
   - `%LOCALAPPDATA%`
   - `%APPDATA%`
   - Desktop
   - Downloads
   - Documents
   - Other user-writable locations

4. **Cleans Per-User Installations**: Removes user-installed Chrome from `%LOCALAPPDATA%\Google\Chrome`

5. **Logs Actions**: Creates daily logs in `C:\Temp` only when actions are taken

## Requirements

- **PowerShell**: Version 5.1 or higher
- **Execution Context**: User-level logon script (via Group Policy)
- **Permissions**: User must have rights to delete items within their own profile
- **Log Directory**: C:\Temp (created automatically if missing)

## Installation & Deployment

### Group Policy Deployment

1. Copy `ChromePortableKiller.ps1` to a network share accessible by all users (e.g., `\\domain\NETLOGON\scripts\`)

2. Configure Group Policy:
   - Open **Group Policy Management Console**
   - Navigate to: `User Configuration` → `Windows Settings` → `Scripts (Logon/Logoff)`
   - Double-click **Logon**
   - Click **PowerShell Scripts** tab
   - Click **Add** and browse to the script location
   - Click **OK** to save

3. Link the GPO to the appropriate Organizational Unit (OU)

4. Test on a pilot group before full deployment

### Manual Testing

```powershell
# Run the script manually (PowerShell as current user)
.\ChromePortableKiller.ps1

# Run with a 10-minute delay before enforcement
.\ChromePortableKiller.ps1 -EnableDelay

# Run with a custom delay (e.g., 2 minutes)
.\ChromePortableKiller.ps1 -EnableDelay -DelayMinutes 2
```

## Logging

Logs are created in `C:\Temp` with the filename format:
```
ChromePortableKiller-YYYYMMDD.log
```

**Example log entry:**
```
---- ChromePortableKiller started for jdoe ----
[2025-12-06 09:15:32] Terminating unauthorized Chrome process PID 1234 at 'C:\Users\jdoe\Downloads\chrome.exe'.
[2025-12-06 09:15:32] Removing unauthorized Chrome executable at 'C:\Users\jdoe\Downloads\chrome.exe'.
[2025-12-06 09:15:33] Removing per-user Chrome directory 'C:\Users\jdoe\AppData\Local\Google\Chrome'.
```

> **Note**: Logs are only created when unauthorized Chrome instances are detected and removed.

## Use Cases

- **Enterprise Browser Management**: Enforce standardized Chrome installations
- **Security Compliance**: Prevent users from running unpatched or outdated browser versions
- **License Compliance**: Ensure all Chrome instances are managed centrally
- **Policy Enforcement**: Block personal Chrome profiles that may bypass security controls

## Important Notes

- ⚠️ **System Chrome is Safe**: System-level installations in Program Files are never touched
- 📊 **User-Level Only**: Script runs in user context and only affects user-writable locations
- 🔄 **Runs at Logon**: Executes automatically when users log in
- 🚫 **Cannot Block New Downloads**: Users can download Chrome again after logon (consider additional GPO restrictions)

## Limitations

- Does not prevent users from downloading Chrome after logon
- Cannot remove Chrome from administrator-protected locations (by design)
- Requires network access if deployed from SYSVOL share

## Recommendations

For comprehensive Chrome management, combine this script with:
- Group Policy restrictions on software installation
- Application whitelisting (e.g., AppLocker)
- Web filtering to block Chrome download sites
- User education and acceptable use policies

## Version History

- **v1.0** (2025-12-06): Initial release
  - Process termination
  - File removal
  - Per-user installation cleanup
  - Action-based logging

## Author

**DPO007**

## License

This script is provided as-is for enterprise use. Modify as needed for your environment.

## Contributing

Contributions, issues, and feature requests are welcome. Feel free to check the issues page if you want to contribute.

---

**⚠️ Disclaimer**: This script is intended for enterprise IT administration. Test thoroughly in a non-production environment before deployment. Always ensure compliance with your organization's policies and applicable laws.
