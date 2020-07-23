<#
===========================================================================
Created on:   7/07/2020 09:08
Created by:   Ben Whitmore
Filename:     DNS_ACL_PTR.ps1
===========================================================================

.SYNOPSIS
The purpose of the script was to update the ACL on legacy DNS objects that existed before ADDHCP was upgraded to a Cluster. DHCP can now update DNS records using the "DNS Update Dynamic Credentials" specified on each DHCP Server in the cluster

.DESCRIPTION
Script to update the ACL on DNS Records imported from a CSV. The CSV should be an Export List of DNS Objects from ADDNS with a column header called "NAME"

.PARAMETER DomainName
Specify the Active Directory Domain Name the DNS Objects belong to

.PARAMETER Account
Specify the SAMAccountName of the "DNS Update Dynamic Credential"

.PARAMETER CSV
Specify the full path to the CSV that contains the DNS record names

.PARAMETER DNSZone
Specify the DNSZone where the DNS records exist. For forward lookup Zones, this may be the same as the DomainName parameter. For reverse lookup zones, enter the PTR format for the nodes in the CSV. e.g." 172.in-addr.arpa"

.PARAMETER ResetLog
Reset the log file each time the script is run

.PARAMETER LogDir
Specify the Log Directory. Default directory is TEMP

.EXAMPLE
DNS_ACL_PTR.ps1 -DomainName "contoso.com" -DNSZone "172.in-addr.arpa" -Account "ddnssvcaccount" -Csv "D:\Scripts\Data\DNSRecords_Export.csv" -ResetLog -LogDir "C:\Logs"
#>

Param
(
    [Parameter(Mandatory = $True)]
    [String]$DomainName,
    [String]$Account,
    [String]$Csv,
    [Switch]$ResetLog,
    [String]$DNSZone,
    [String]$LogDir = $ENV:TEMP
)

#Set Logging Location
$Script:LogFile = $LogDir + "\DNS_ACL.log"

#Update console with progress
Write-Output ""
Write-Output "-----------------------------"
Write-Output "Running DNS_ACL....."
Write-Output "-----------------------------"
Write-Output ""
Write-Output "Logging to:" $LogFile

#Get Current Date/Time
$LogD = Get-Date -f yyyy-MM-dd
$LogT = Get-Date -f hh-mm-ss
$LogTimeStamp = $LogD + "_" + $LogT

#Format New lines
$NewLogLine = "`r`n "

#Check if log should be reset
If ($ResetLog -eq $True) {
    #Reset Log FIle and Write Date/Time to Log File
    $NewLogLine + "############################################" > $LogFile
}
else {
    #Write Date/Time to Log File
    $NewLogLine + "############################################" >> $LogFile
}

#Format Log File
"-----------------------------" >> $LogFile
"Current Date/Time: " + $LogTimeStamp >> $LogFile
"-----------------------------" >> $LogFile 
$NewLogLine + "############################################" >> $LogFile
$NewLogLine >> $LogFile 
$NewLogLine + "CSV imported from " + $Csv >> $LogFile
$NewLogLine >> $LogFile

#Import CSV Objects
$Computers = Import-Csv -path $Csv

#Get SID of Account
$AccountSID = (Get-ADUser $Account).SID

# Alternative query to process only the first few lines of the CSV for testing.
# ForEach ($Computer in ($Computers | Select-Object -First 20)) {
    
#Process each row in the CSV
ForEach ($Computer in ($Computers) ) {

    #Reverse normal IP into PTR record format - Thanks Adam the Automator
    $IPAddress = $Computer.Name
    $Array = $IPAddress.Split('.')
    $Record = "{0}.{1}" -f $Array[3], $Array[2]

    #Get the full path for the object in DNS
    $Path = "AD:DC=$($Record),DC=$DNSZone,CN=MicrosoftDNS,DC=DomainDnsZones,DC=$($DomainName.Split('.') -join ',DC=')" 

    #Test if the record exists
    If (!(Test-Path -Path $Path )) {
        Write-Warning "Record ""$($Record)"" not found, skipping"
        Write-Output "Record ""$($Record)"" not found, skipping" >> $LogFile
    }
    else {

        #Create an object for the new access rule allowing full permission
        $AccessRule = New-Object System.DirectoryServices.ActiveDirectoryAccessRule($AccountSID, "GenericAll", "Allow")

        #Get existing ACL from AD DNS Object
        $Acl = Get-Acl -Path $Path

        #Append the access rule to the ACL
        $Acl.AddAccessRule($AccessRule)

        #Commit the new ACL to the AD DNS Object
        Set-Acl -Path $Path -AclObject $Acl

        #Output
        Write-Output "ACL Updated for DNS PTR Record $($Computer.Name)" 
        Write-Output "ACL Updated for DNS PTR Record $($Computer.Name)" >> $LogFile
    }
}