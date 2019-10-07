# DNS  
**Get-DomainDNS**  
Currently in development  
The Purpose of these functions is to update all Domain Member Server DNS Addresses. After performing a DCPROMO and adding new Domain DNS Servers, this script can be used with SCCM to quickly update all member Servers DNS information.  
**3 Functions**  
 Get-DNSInfo  
 Set-DNSInfo  
 Set-DNSInfoAddress  
##############  
**Get-DNSInfo**  
##############  
Returns the DNS Address/es as an array for a Domain Connected Adapter (If one exists)  
##############  
**Set-DNSInfo**  
##############  
The New DNS Address/es are passed as parameters to this function  
##############  
**Get-DNSInfoAddress**  
##############  
Parameters from Set-DNSInfo are passed to this function which actually updates the client DNS for the Domain Connected Adapter using Set-DnsClientServerAddress  
