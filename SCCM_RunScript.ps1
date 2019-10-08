param(
[String]$NewDNS
)

Import-Module "\\YourServer\DNS\DNSInfo\DNSInfo.psm1" -Force

Set-DNSInfo -NewDNS $NewDNS -Backup -ResetLog -SkipDHCPCheck -BackupDir "C:\Windows\Logs" -LogDir "C:\Windows\Logs"