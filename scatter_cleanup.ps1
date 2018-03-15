<# Variable Declarations#> 
$ver = Read-Host "Please enter the package name (needs to be the same as folder name)"
$targets = Get-Content C:\Windows\Temp\CPT\SCC_Results\scc_success.txt


foreach ($target in $targets) {
    robocopy \\$target\c$\windows\temp\CPT\SCC\ C:\Windows\Temp\CPT\SCC_Results\$target /move /S /LOG+:C:\Windows\Temp\CPT\robo_logs\$target.log
    }