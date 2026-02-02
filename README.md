# PowerShell Admin Toolkit

A collection of practical PowerShell scripts for IT administrators. Covers Microsoft 365 / Entra ID / Graph management, Exchange Online reporting, Windows Autopilot, server hardening, software removal, WSUS client management, and basic asset inventory.

## Included Scripts

| Script                            | Purpose                                                                 | Last Updated       |
|-----------------------------------|-------------------------------------------------------------------------|--------------------|
| `AppID.ps1`                       | Retrieve Entra ID app registrations, service principals, owners, cross-tenant access via Microsoft Graph | 19 minutes ago    |
| `Get-WindowsAutoPilotInfo.ps1`    | Collect Autopilot hardware hash + device info (local/remote), export CSV, optional Intune upload | 13 minutes ago    |
| `GetDistributionList.ps1`         | Report all members of Exchange Online distribution groups (renamed & updated) | now               |
| `GraphPermissions.ps1`            | Audit Graph API permissions assigned to apps / service principals       | 29 minutes ago    |
| `MailboxDelegationReport.ps1`     | Generate CSV report of mailbox FullAccess / SendAs / SendOnBehalf permissions | 12 minutes ago    |
| `RemoveIIS.ps1`                   | Remove IIS and related Windows features from servers (hardening)        | 11 minutes ago    |
| `Uninstall-Autodesk.ps1`          | Silently detect and remove Autodesk products                            | 29 minutes ago    |
| `WSUS-Checkin.ps1`                | Force WSUS client check-in, scan, report & install                      | 29 minutes ago    |
| `Win10Computers.ps1`              | Gather inventory details of Windows 10/11 computers                     | 29 minutes ago    |

## Features Overview

- **Microsoft 365 / Entra ID / Graph** — App & permission auditing, cross-tenant info
- **Exchange Online** — Mailbox delegation & distribution group membership reporting
- **Autopilot** — Hardware hash collection + optional online registration
- **Server Hardening** — Easy removal of IIS and related services
- **Software Management** — Bulk uninstall of common vendor software (Autodesk)
- **Patch Management** — Trigger WSUS client actions
- **Asset Inventory** — Basic Windows device details collection

## Requirements

- PowerShell 5.1 or **PowerShell 7+** recommended
- For Graph / Entra ID / Intune scripts:
  - `Microsoft.Graph.*` modules (`Microsoft.Graph.Authentication`, `Microsoft.Graph.Applications`, etc.)
- For Exchange scripts:
  - `ExchangeOnlineManagement` module
- Administrator rights (local or remote) where required
- Internet access for cloud-based cmdlets

## Quick Usage Examples

```powershell
# Get all Entra app registrations + owners
.\AppID.ps1

# Collect Autopilot info from remote PC
.\Get-WindowsAutoPilotInfo.ps1 -ComputerName PC0123 -OutputFile .\autopilot-PC0123.csv

# Report distribution group members
.\GetDistributionList.ps1

# Audit Graph permissions
.\GraphPermissions.ps1

# Mailbox delegation report
.\MailboxDelegationReport.ps1

# Remove IIS from this server
.\RemoveIIS.ps1

# Uninstall all detected Autodesk products
.\Uninstall-Autodesk.ps1

# Force WSUS check-in
.\WSUS-Checkin.ps1
