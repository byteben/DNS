# DNS__
**Get-DomainDNS**__
Currently in development__
The Purpose of these functions is to update all Domain Member Server DNS Addresses. After performing a DCPROMO and adding new Domain DNS Servers, this script can be used with SCCM to quickly update all member Servers DNS information.__
**3 Functions**__
 Get-DNSInfo__
 Set-DNSInfo__
 Set-DNSInfoAddress__ 
##############__ 
**Get-DNSInfo**__
##############__
Returns the DNS Address/es as an array for a Domain Connected Adapter (If one exists)__
############## __
**Set-DNSInfo**__
##############__
The New DNS Address/es are passed as parameters to this function__
##############__
**Get-DNSInfoAddress**__
##############__
Parameters from Set-DNSInfo are passed to this function which actually updates the client DNS for the Domain Connected Adapter using Set-DnsClientServerAddress__
