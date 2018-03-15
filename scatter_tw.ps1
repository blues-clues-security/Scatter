<# Variable Definitions #>
$ver = Read-Host "Please enter the package name (needs to be the same as folder name)"
$timeoff = New-TimeSpan -Hours 1 -Minutes 30
$reminder = (Get-Date) + $timeoff
$errorfolder = Test-Path C:\Windows\Temp\CPT\robo_logs
$resultsfolder = Test-Path C:\Windows\Temp\CPT\SCC_results
$packagetest = Test-Path $ver 

<# Check if the user created the package folder, or spelled it correctly#>
while ($packagetest -eq $false) {
    Write-Host "Invalid Path"
    Write-Host "`n"
    $ver = Read-Host "Please enter the package name (needs to be located C:\Windows\Temp\CPT\SCC\ )"
    $packagetest = Test-Path C:\Windows\Temp\CPT\SCC\$ver
}
<# Assign the location variables after user input has been confirmed#>
$stig = Get-ChildItem C:\Windows\Temp\CPT\SCC\$ver *.zip | Select-Object ($_.Name)
$targets = Get-Content C:\Windows\Temp\CPT\SCC\$ver\$ver.txt

<# Create robo_logs folder on operator box if it does not exist#>

if ($errorfolder -eq $false ){
    mkdir C:\Windows\Temp\CPT\robo_logs | Out-Null
    Continue
}
else {

    if ($resultsfolder -eq $false ) {
        mkdir C:\Windows\Temp\CPT\SCC_results | Out-Null
        Continue
    }
    else {

        <# Ask the operator if they configured the SCC packages on their local box#>
        Write-Host "`n"
        Write-Host "Did you configure your C:\Windows\Temp\CPT\Package# folder?"
        $op_check1 = Read-Host "Yes or No"
            while ("yes","no" -notcontains $op_check1)
            {
                Write-Host "Please type Yes or No"
	            $op_check1 = Read-Host "Yes or No"
                Write-Host "-----------------------------------------"
            }
            if (($op_check1 -eq "no")) {
                Write-Host "Then how does the script know what targets to hit, or what version of SCC to use, or the STIG file to run against your targets?"
                Write-Host "Idiot"
                Write-Host "`n"
                Exit
            }
            elseif (($op_check1 -eq "yes")) {

                <# Ask the operator if they configured the cscc file on their local box#>
                Write-Host "`n"
                Write-Host "Did you configure your cscc file within each package?"
                $op_check2 = Read-Host "Yes or No"
                while ("yes","no" -notcontains $op_check2) {
                    Write-Host "Please type Yes or No"
	                $op_check2 = Read-Host "Yes or No"
                    Write-Host "-----------------------------------------"
                }
                if (($op_check2 -eq "no")) {
                    Write-Host "Then where is your SCC results going on the target box?"
                    Write-Host "Idiot"
                    Write-Host "`n"
                    Exit
                }
                elseif (($op_check2 -eq "yes")) {
                
                    Write-Host "-----------------------------------------"

                    <# Executes on every host listed in file defined in $targets #>
                    foreach ($target in $targets) {
                        
                        <# Tell the operator what target is currently being processed #>
                        Write-Host "Beginning transfer to $target"

                        <# Create directory for robocopy logs based on the target IP, this is different than the results folder which is underneath C:\Windows\Temp\CPT\SCC_Results#>     
                        robocopy C:\Windows\Temp\CPT\SCC\$ver \\$target\c$\Windows\Temp\CPT\SCC /MIR /LOG+:C:\Windows\Temp\CPT\robo_logs\robocopy.log
    
                        <# Error handling for Robocopy #>
                        if (($LASTEXITCODE -eq 0)) {
                            $robomessage = "No failure was encountered"
                        }
                        elseif (($LASTEXITCODE -eq 1)) {
                            $robomessage = "All files were copied successfully"
                        }
                        elseif (($LASTEXITCODE -eq 2)) {
                            $robomessage = "There are some additional files in the destination directory that are not present in the source directory. No files were copied."
                        }
                        elseif (($LASTEXITCODE -eq 3)) {
                            $robomessage = "Some files were copied. Additional files were present. No failure was encountered."
                        }
                        elseif (($LASTEXITCODE -eq 5)) {
                            $robomessage = "Some files were copied. Some files were mismatched. No Failure was encountered."
                        }
                        elseif (($LASTEXITCODE -eq 6)) {
                            $robomessage = "Additional files and mismatched files exist. No files were copied and no failures were encountered. This means that the files already exist in the destination directory."
                        }
                        elseif (($LASTEXITCODE -eq 7)) {
                            $robomessage = "Files were copied, a file mismatch was present, and additional files were present."
                        }
                        elseif (($LASTEXITCODE -gt 8)) {
                            $robomessage = "Files did not copy"
                        }
                        else {
                            $robomessage = "Unknown error, your princess is in another castle!"
                        }

                    <# Display error message to operator #>
                        Write-Host "`n"
                        Write-Host $robomessage
                        Write-Host "-----------------------------------------"

                    <# If robocopy did not work, create a log.txt file for the operator to check in a folder named after the target #>
                        if (($LASTEXITCODE -gt 8)) {
                            Write-Host "Information is logged for client $target ; Continuing to next hosts..."
                            Get-Date >> C:\Windows\Temp\CPT\robo_logs\errorlog.txt
                            $target >> C:\Windows\Temp\CPT\robo_logs\errorlog.txt
                            $robomessage >> C:\Windows\Temp\CPT\robo_logs\errorlog.txt
                            Continue
                        }

                    <# If no error was encountered, attempt to run SCC on target #>
                        else { 
                            Write-Host "Running SCC on remote host $target"
                            Write-Host "`n"

                    <# WMIC process call on the remote box to run SCC#>
                    <# Note: SCC must be configured on the local box before being pushed out (use --config)#>
                            wmic /node:$target process call create "cmd.exe /c C:\Windows\Temp\CPT\SCC\scc_4.2\cscc.exe -isr C:\Windows\Temp\CPT\SCC\$stig"
        
                    <# Wait 2 mins for the host to create a "Results" directory and check if it exists#>
                            Start-Sleep -s 30

                            $scc_results = Test-Path \\$target\c$\Windows\Temp\CPT\SCC\Logs

                    <# Check if SCC ran successfully #>
                            if (($scc_results -eq $true)) {
                                Write-Host "SCC ran successfully on remote host - $target"
                                Write-Host "-----------------------------------------"
 
                    <# Create a directory on Operator box to transfer the SCC results to #>
                                Write-Host " Creating local directory for results at C:\Windows\Temp\CPT\SCC_results\$target"
                                Write-Host "`n"
                                mkdir C:\Windows\Temp\CPT\SCC_Results\$target | Out-Null

                    <# Remind operator to run cleanup script in an hour#>
                                Write-Host "Don't forget to run 'Scatter Cleanup Script' against $target after $reminder"
                                Write-Host "`n"
                                $target >> C:\Windows\Temp\CPT\SCC_Results\scc_success.txt
                            }
                    <# If SCC did not create a "Results" folder then put an error file in the SCC_Results folder#>
                            else {
                                Write-Host "SCC failed to run properly on remote host - $target"
                                Write-Host "Creating error log for SCC at C:\Windows\Temp\CPT\SCC_Results\scc_error.txt"
                                $target >> C:\Windows\Temp\CPT\SCC_Results\scc_error.txt
                                Write-Host "`n"
                                Write-Host "-----------------------------------------"
                            }
                        }
                    }
                   }
        }
    }
}