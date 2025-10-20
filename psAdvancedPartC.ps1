<#
.SYNOPSIS
    Advanced AD Audit Example – demonstrates PowerShell functions, grouping, exporting, 
    calculated properties, and robust error handling.

.DESCRIPTION
    Reads AD data from a JSON export, filters inactive users, detects expiring accounts,
    and generates a formatted executive report.
#>

# --------------------------
# Function: Get-InactiveAccounts
# --------------------------
function Get-InactiveAccounts {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [int]$Days = 30
    )

    try {
        $threshold = (Get-Date).AddDays(-$Days)
        $inactive = $data.users | Where-Object {
            try {
                ([datetime]$_.lastLogon) -lt $threshold
            } catch {
                Write-Warning "Could not parse lastLogon for user $($_.samAccountName)"
                $false
            }
        }
        return $inactive
    } catch {
        Write-Error "Error occurred in Get-InactiveAccounts: $_"
    }
}

# --------------------------
# Load JSON data
# --------------------------
try {
    $data = Get-Content -Path "ad_export.json" -Raw | ConvertFrom-Json
} catch {
    Write-Error "Failed to load or parse ad_export.json. Error: $_"
    exit
}

# --------------------------
# Data Analysis
# --------------------------

# Inactive users (30+ days)
$inactiveUsers = Get-InactiveAccounts -Days 30

# Users with passwords older than 90 days
$oldPasswords = $data.users | Where-Object {
    try {
        ((Get-Date) - [datetime]$_.passwordLastSet).Days -gt 90
    } catch {
        Write-Warning "Invalid passwordLastSet date for $($_.samAccountName)"
        $false
    }
}

# Accounts expiring within 30 days
$expiringAccounts = $data.users | Where-Object {
    try {
        ([datetime]$_.accountExpires) -lt (Get-Date).AddDays(30)
    } catch {
        Write-Warning "Invalid accountExpires date for $($_.samAccountName)"
        $false
    }
}

# Computers not seen in 30+ days
if ($data.PSObject.Properties.Name -contains 'computers') {
    $staleComputers = $data.computers | Where-Object {
        try {
            ([datetime]$_.lastLogon) -lt (Get-Date).AddDays(-30)
        } catch {
            Write-Warning "Invalid computer lastLogon for $($_.name)"
            $false
        }
    }
} else {
    $staleComputers = @()
}

# --------------------------
# Generate Executive Report
# --------------------------
$report = @"
====================================================
            ACTIVE DIRECTORY EXECUTIVE REPORT
====================================================

Domain:             $($data.domain)
Export Date:        $($data.export_date)
Domain Controllers: $($data.domain_controllers -join ", ")

----------------------------------------------------
EXECUTIVE SUMMARY
----------------------------------------------------
Total Users:               $($data.users.Count)
Inactive Users (30+ days): $($inactiveUsers.Count)
Expiring Accounts (30 days): $($expiringAccounts.Count)
Old Passwords (>90 days):  $($oldPasswords.Count)
Stale Computers (30+ days): $($staleComputers.Count)

----------------------------------------------------
WARNINGS
----------------------------------------------------
$(if ($expiringAccounts.Count -gt 0) { "⚠️  Some accounts expire within 30 days." } else { "✅ No accounts expiring soon." })
$(if ($oldPasswords.Count -gt 0) { "⚠️  Some users have passwords older than 90 days." } else { "✅ All passwords within age limit." })
$(if ($staleComputers.Count -gt 0) { "⚠️  Some computers have not checked in for 30+ days." } else { "✅ All computers are active." })

----------------------------------------------------
DETAILS: INACTIVE USERS
----------------------------------------------------
$($inactiveUsers | Select-Object displayName, samAccountName, department, lastLogon | Format-Table -AutoSize | Out-String)

----------------------------------------------------
DETAILS: EXPIRING ACCOUNTS
----------------------------------------------------
$($expiringAccounts | Select-Object displayName, samAccountName, accountExpires | Format-Table -AutoSize | Out-String)

----------------------------------------------------
DETAILS: STALE COMPUTERS
----------------------------------------------------
$($staleComputers | Select-Object name, site, lastLogon | Sort-Object lastLogon | Select-Object -First 10 | Format-Table -AutoSize | Out-String)

====================================================
END OF REPORT
====================================================
"@

# Save the report
$report | Out-File -FilePath "AD_Executive_Report.txt" -Encoding UTF8

Write-Host "✅ Report generated successfully: AD_Executive_Report.txt"
