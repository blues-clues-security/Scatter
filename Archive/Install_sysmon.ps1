$Servers = Get-Content C:\Users\USAF_Admin\Desktop\Hosts.txt

foreach ($s in $Servers)
{
Robocopy C:\Tools\microsoft\sysinternals\ \\$s\c$\Temp\CPT\ Sysmon.exe /sec /log+:Install_Log.txt
wmic /node:$s process call create "cmd.exe /c C:\Temp\CPT\Sysmon.exe -i -accepteula"

}