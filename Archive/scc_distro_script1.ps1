$s = C:\Temp\SCC_Packages\Hosts.txt
$ver = (enter SCC filename)

foreach ($s in servers) {
	Write-Host "Beginning transfer to $s"
    
    robocopy C:\Temp\CPT\$ver \\$s\c$\Temp\CPT\SCC /MIR /sec /log+:C:\Temp\CPT\SCC_logs\$s.log
    
    if (($LASTEXITCODE -eq 0)) {
        $robomessage = "Succeded"
    }
    elseif (($LASTEXITCODE -gt 0) -and ($LASTEXITCODE -lt 16)) {
        $robomessage = "Warning"
    }
    elseif (($LASTEXITCODE -eq 16)) {
        $robomessage = "Error"
    }
    else {
        $robomessage = "Unknown error, your princess is in another castle!"
    }
    
    Write-Host $robomessage

    if (($LASTEXITCODE -gt 0)) {
        Write-Host "File distribution error"
        Write-Host "Information is logged for client $s ; Continuing to next hosts..."
        $s >> C:\Temp\CPT\robo_error_logs\log.txt
        $robomessage >> C:\Temp\CPT\robo_error_logs\log.txt
        Continue
    }
    else { 
        Write-Host "Running SCC on remote host $s"
        wmic /node:$s process call create "cmd.exe /c \\$s\c$\Temp\CPT\SCC\$ver\cscc.exe -isr ..."

        if (($LASTEXITCODE -eq 0) -or ($LASTEXITCODE -eq 1)) {
            Write-Host "SCC ran successfully on remote host - $s"
 
            Write-Host " Creating local directory for results at C:\Temp\CPT\SCC_results\$s"
            mkdir C:\Temp\CPT\SCC_Results\$s

            Write-Host "Transferring files from $s"
            robocopy \\$s\c$\Temp\CPT\SCC C:\Temp\CPT\SCC_Results\$s /move 
        }
        else {
            Write-Host "SCC failed to run properly on remote host - $s"
            Write-Host "Creating error log for SCC at C:\Temp\CPT\SCC_Results\"
            $LASTEXITCODE >> C:\Temp\CPT\SCC_Results\$s\scc_error.txt

        }
    }
}