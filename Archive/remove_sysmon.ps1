$Servers = Get-Content C:\Users\USAF_Admin\Desktop\Hosts.txt

foreach ($s in $Servers)
{
wmic /node:$s process call create "cmd.exe /c C:\Temp\CPT\Sysmon.exe -u"
start-sleep -s 2
Robocopy C:\Temp\CPT\ \\$s\c$\Temp\CPT\ Sysmon.exe /R:2 /E /purge /sec /log+:Remove_Log.txt

}