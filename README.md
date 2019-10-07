# DNS 
  
Scripts for DNS Function on Windows Clients  
  
**-------------------------------------------**  
**DNSInfo.psm1** (Currently in development)  
**-------------------------------------------**  
  
The Purpose of these functions is to update all Domain Member Server DNS Addresses. After performing a DCPROMO and adding new Domain DNS Servers, this script can be used with SCCM to quickly update all member Servers DNS information.  
  
**3 Functions**  
 Get-DNSInfo  
 Set-DNSInfo  
 Set-DNSInfoAddress  
   
**Installation**  

Import-Module DNSInfo  
   
##############  
**Get-DNSInfo**  
##############  
Returns the DNS Address/es as an array for a Domain Connected Adapter (If one exists) 
  
##############  
**Set-DNSInfo**  
##############  
DNS Address/es are passed as parameters to this function. COnditional logic is applied to check if the client has a "Domain Connected" adapter and whether it is a DHCP Client. By default you are asked if you want to continue the operation for a DHCP client. This check can be bypassed by using the -SkipDHCPCheck parameter.  
  
**Parameters**  
.PARAMETER LogDir  
Specify the Directory to save DNSInfo.log to. %TEMP% is the default directory  
  
.PARAMETER NewDNS  
Specify the new Client DNS Servers, in order of preference  
  
.PARAMETER Backup  
Choose to backup the existing DNS Addresses for recovery  
  
.PARAMETER BackupDir  
Specify the folder to backup the existing DNS Addresses for recovery. %TEMP% is the default directory  
  
.PARAMETER LogDir  
Specify folder for DNSInfo.log  
  
.PARAMETER ResetLog  
Specify if existing log file should be overwritten  
  
.PARAMETER SkipDHCPCheck  
Specify if the script should check if the Client gets it's IP Address from a DHCP server  
  
##############  
**Set-DNSInfoAddress**  
##############  
Parameters from the Set-DNSInfo function are passed to this function which actually updates the client DNS for the Domain Connected Adapter using Set-DnsClientServerAddress  
  
**-------------------------------------------**  
