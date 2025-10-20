# Load JSON
$data = Get-Content -Path "ad_export.json" -Raw | ConvertFrom-Json

Write-Host "Domain: $($data.domain)"
Write-Host "Export Date: $($data.export_date)"
Write-Host ""

# === 1. Find users inactive for 30+ days ===
$threshold = (Get-Date).AddDays(-30)
$inactiveUsers = $data.users | Where-Object { 
    ([datetime]$_.lastLogon) -lt $threshold
}

# Export to CSV
$inactiveUsers | Export-Csv -Path "inactive_users.csv" -NoTypeInformation -Encoding UTF8
Write-Host "Inactive users exported to inactive_users.csv"
Write-Host ""

# === 2. Calculate password age (in days) ===
$usersWithPwdAge = $data.users | Select-Object displayName, samAccountName, department, @{
    Name = 'PasswordAgeDays'
    Expression = { ((Get-Date) - [datetime]$_.passwordLastSet).Days }
}

Write-Host "Password ages:"
$usersWithPwdAge | Format-Table -AutoSize
Write-Host ""

# === 3. Group computers per site ===
# (Example assumes 'computers' exists in your JSON)
if ($data.PSObject.Properties.Name -contains 'computers') {
    Write-Host "Computers grouped per site:"
    $data.computers | Group-Object -Property site | ForEach-Object {
        Write-Host " - $($_.Name): $($_.Count) computers"
    }

    # === 4. List top 10 computers that haven't checked in longest ===
    Write-Host ""
    Write-Host "Top 10 computers that haven't checked in the longest time:"
    $data.computers | Sort-Object -Property lastLogon | Select-Object -First 10 | 
        Select-Object name, site, lastLogon | Format-Table -AutoSize
}
else {
    Write-Host "⚠️ No 'computers' array found in JSON."
}
