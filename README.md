# DNS 
  
Scripts for DNS Function on Windows Clients  

**-------------------------------------------**  
**DNS_ACL.ps1** (Currently in development)  
**-------------------------------------------**  

The purpose of this script is to change the ACL on DNS objects.
When we moved DHCP from a single box to a cluster we implemented the DNS Dynamic Account Credential to allow DHCP servers to create and update new DNS records.
This account did not have permissions on legacy DNS objects so if the client received a new DHCP request the ADDNS account did not have permissions to update the IP address

The DNS objects are exported to a list from ADDNS and filtered/saved as a CSV. The script will then pull the CSV rows into an array and updte the ACL for each AD Object.
Currently, only A Records are in scope. Further development is in process to handle the ACL on RPTR DNS Records too. Feel free to contribute!

**EXAMPLE**
DNS_ACL.ps1 -DomainName "contoso.com" -Account "ddnssvcaccount" -Csv "D:\Scripts\Data\DNSRecords_Export.csv" -ResetLog -LogDir "C:\Logs"
  
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
  
**Example**  
  
  .EXAMPLE
Set-DNSInfo -NewDNS "1.1.1.1,2.2.2.2,3.3.3.3,4.4.4.4" -Backup -ResetLog -SkipDHCPCheck -BackupDir "C:\Logs" -LogDir "C:\Logs"  
  
##############  
**Set-DNSInfoAddress**  
##############  
Parameters from the Set-DNSInfo function are passed to this function which actually updates the client DNS for the Domain Connected Adapter using Set-DnsClientServerAddress  
  
  
##############  
**SCCM_RunScript.ps1**  
##############  
Example of a script to publish in SCCM to leverage DNSInfo. Default Parameter has to be a quoted string to pass multiple IP addresses e.g. "1.1.1.1,2.2.2.2,3.3.3.3,4.4.4.4"  
  
**-------------------------------------------**  
