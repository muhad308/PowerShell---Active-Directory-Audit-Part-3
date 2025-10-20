# 1. Läs in JSON-filen med Get-Content och ConvertFrom-Json
$data = Get-Content -Path "ad_export.json" -Raw | ConvertFrom-Json

# 2. Visa domännamn och exportdatum
Write-Host "Domain: $($data.domain)"
Write-Host "Export Date: $($data.export_date)"
Write-Host ""

# 3. Lista alla användare som inte loggat in på 30+ dagar
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

# 4. Räkna antal användare per avdelning med enkel loop
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
