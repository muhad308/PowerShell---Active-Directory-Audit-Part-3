# 1. Load the JSON file with Get-ContentandConvertFrom-Json
$data = Get-Content -Path "ad_export.json" -Raw | ConvertFrom-Json

# 2. View domain name and export date
Write-Host "Domain: $($data.domain)"
Write-Host "Export Date: $($data.export_date)"
Write-Host ""

# 3. List all users who have not logged in for 30+ days
$thresholdDate = (Get-Date).AddDays(-30)
$inactiveUsers = @()  # Create an empty array

foreach ($user in $data.users) {
    $lastLogon = [datetime]$user.lastLogon
    if ($lastLogon -lt $thresholdDate) {
        $inactiveUsers += $user
    }
}

Write-Host "Users inactive for 30+ days:"
foreach ($user in $inactiveUsers) {
    Write-Host " - $($user.displayName) ($($user.samAccountName)) last logged in: $($user.lastLogon)"
}
Write-Host ""

# 4. Count number of users per department with a simple loop
$deptCount = @{}  # Create an empty hashtable

foreach ($user in $data.users) {
    $dept = $user.department
    if ($deptCount.ContainsKey($dept)) {
        $deptCount[$dept] += 1
    } else {
        $deptCount[$dept] = 1
    }
}

Write-Host "Number of users per department:"
foreach ($dept in $deptCount.Keys) {
    Write-Host " - $dept : $($deptCount[$dept])"
}
