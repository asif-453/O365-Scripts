# PowerShell Admin Toolkit

A collection of practical, production-ready PowerShell scripts for Microsoft 365 / Entra ID / Microsoft Graph administration, Exchange Online reporting, Windows Autopilot device management, server hardening, software cleanup, WSUS patching, and basic Windows asset inventory.


## Features at a Glance

- Entra ID / Microsoft Graph app & permission auditing
- Exchange Online mailbox delegation + distribution group membership reports
- Windows Autopilot hardware hash collection & optional Intune import
- Server hardening (remove unnecessary roles like IIS)
- Silent uninstall of common vendor software (Autodesk example)
- WSUS client force check-in & scan
- Basic Windows 10/11 device inventory gathering

## Table of Scripts

| Script                            | Description                                                                 | Authentication / Scope                  | Output          | Last Updated (approx.) |
|-----------------------------------|-----------------------------------------------------------------------------|-----------------------------------------|-----------------|------------------------|
| `AppID.ps1`                       | List Entra ID app registrations, service principals, owners, cross-tenant access | Microsoft Graph (interactive)           | CSV             | Recent                 |
| `Get-WindowsAutoPilotInfo.ps1`    | Collect Autopilot device info (hash, serial, model…) – local/remote support | Microsoft Graph / Intune (optional)     | CSV             | Recent                 |
| `GetDistributionList.ps1`         | Report all user members of Exchange distribution groups                     | Exchange Online                         | CSV             | Very recent            |
| `GraphPermissions.ps1`            | Audit Graph API permissions granted to apps & service principals            | Microsoft Graph                         | Console / CSV   | Recent                 |
| `MailboxDelegationReport.ps1`     | CSV report of FullAccess, SendAs, SendOnBehalf permissions across mailboxes | Exchange Online                         | CSV             | Recent                 |
| `RemoveIIS.ps1`                   | Remove IIS + WAS features from Windows Server (hardening)                   | Local admin rights                      | Console         | Recent                 |
| `Uninstall-Autodesk.ps1`          | Detect and silently uninstall Autodesk products                             | Local admin rights                      | Console         | Recent                 |
| `WSUS-Checkin.ps1`                | Force WSUS client check-in, detection, reporting & install                  | Local rights                            | Console         | Recent                 |
| `Win10Computers.ps1`              | Gather hardware/software details of Windows 10/11 machines                  | AD / WMI access                         | CSV / Console   | Recent                 |

## Requirements

- **PowerShell**: 7.2+ recommended (5.1 still works for most scripts)
- **Modules**:
  - `Microsoft.Graph.Authentication`, `Microsoft.Graph.Applications`, `Microsoft.Graph.Identity.DirectoryManagement` (for Graph scripts)
  - `ExchangeOnlineManagement` (for Exchange scripts)
- **Permissions**: Graph/Exchange consents + local admin rights where needed
- **Execution Policy**: At least `RemoteSigned`

Install required modules (run once):

```powershell
Install-Module Microsoft.Graph -Scope CurrentUser
Install-Module ExchangeOnlineManagement -Scope CurrentUser


Quick Start Examples

# 1. Audit Entra ID applications
.\AppID.ps1

# 2. Get Autopilot info from a remote computer
.\Get-WindowsAutoPilotInfo.ps1 -ComputerName "PC-12345" -OutputFile ".\Autopilot-PC-12345.csv"

# 3. Generate distribution group membership report
Connect-ExchangeOnline
.\GetDistributionList.ps1

# 4. Check Graph API permissions
.\GraphPermissions.ps1

# 5. Mailbox delegation overview
Connect-ExchangeOnline
.\MailboxDelegationReport.ps1

# 6. Hardening – remove IIS from this server
.\RemoveIIS.ps1

# 7. Clean up Autodesk software
.\Uninstall-Autodesk.ps1

# 8. Trigger WSUS check-in & install
.\WSUS-Checkin.ps1
