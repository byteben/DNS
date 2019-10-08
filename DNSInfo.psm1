<#	
	===========================================================================
	 Created on:   	07/10/2019 11:08
	 Created by:   	Ben Whitmore
	 Organization: 	
	 Filename:     	DNSInfo.psm1
	-------------------------------------------------------------------------
	 Module Name: DNSInfo
    ===========================================================================
    
    Version:
    1.1.0   08/10/2019  Ben Whitmore - Thanks to @guyrleech
    -Changed NewDNS parameter to a string from an array so it can be used easily with SCCM Run Script. 
    SCCM flattens the array if you pass objects in a string e.g. 1.1.1.1,2.2.2.2,3.3.3.3
    -String is then split and IP address match is tested. Invalid IP address ends the script and is logged
    -NewDNS Parameter must be passed with "" e.g "1.1.1.1,2.2.2.2,3.3.3.3"

    1.0.2   07/10/2019  Ben Whitmore - Thanks to @IISResetMe
    Used Switch for Parameters -Backup, -SkipDHCPCheck, -ResetLog, -NoOutPut

    1.0.1   07/10/2019  Ben Whitmore
    Updated Validate Set for Set-DNSInfo Parameters

    1.0.0   06/10/2019  Ben Whitmore
    Initial Release
#>

Function Get-DNSInfo {
    <#

	.DESCRIPTION
Function to Get DNS Addresses from Domain Joined clients

.EXAMPLE
Get-DNSInfo -NoOutput

.PARAMETER NoOutPut
Doesn't output current DNS information

#>
    [CmdletBinding()]
    Param
    (
        [Switch]$NoOutput = $False
    )

    #Get Domain Connected Network Adapter
    $Script:DomainAdapter = Get-NetConnectionProfile | Where-Object { $_.NetworkCategory -eq 'DomainAuthenticated' } | Select-Object InterfaceIndex, InterfaceAlias, NetworkCategory

    #Perform actions if adapter is Domain Authneticated only
    If (($DomainAdapter.NetworkCategory -eq 'DomainAuthenticated')) {

        #Check if Domain Connected Network Adapter has obtained a DHCP Lease
        $DHCPClientCheck = Get-NetIPAddress | Where-Object { ($_.InterfaceIndex -eq $DomainAdapter.InterfaceIndex) -and ($_.PrefixOrigin -eq 'dhcp') }

        #Get DNS Addresses from the Domain Connected Network Adapter
        $DNSAddresses = Get-DnsClientServerAddress | Where-Object { ($_.InterfaceIndex -eq $DomainAdapter.InterfaceIndex) -and ($_.AddressFamily -eq '2') } | Select-Object -expand Address

        #Set DHCP Variable when the IP is obtained from a DHCP Server
        If (!$DHCPClientCheck) { 
            $DHCPEnabled = "False"
        } 
        else {
            $DHCPEnabled = "True"
        }
        
        #Put infomration into an array
        $DNSArray = New-Object PSObject -Property @{
            DNS_Addresses = $DNSAddresses
            DHCP_Enabled  = $DHCPEnabled
        }

        #If the Function was run without the $NoOutPut Parameter then display the Current DNS Information
        If ($NoOutput -eq $False) {
            $DNSArray
        }
    }
    else {
        If ($NoOutput -eq $False) {
            write-host "This host is not connected to a Domain"
        }
    }
}

Function Set-DNSInfo {
    <#

.DESCRIPTION
Function to set new DNS Addresses for Domain Joined clients

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

.EXAMPLE
Set-DNSInfo -NewDNS 1.1.1.1,2.2.2.2,3.3.3.3,4.4.4.4 -Backup -ResetLog -SkipDHCPCheck -BackupDir "C:\Logs" -LogDir "C:\Logs"

    #>

    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $True)]
        [String]$NewDNS,
        [Switch]$Backup = $False,
        [Switch]$ResetLog = $False,
        [String]$LogDir = $ENV:TEMP,
        [String]$BackupDir = $ENV:TEMP,
        [Switch]$SkipDHCPCheck = $False
    )

    #Split $NewDNS String
    $NewDNSArray = $NewDNS.split(',')
    #Check all IPs are valid
    ForEach ($IP in $NewDNSArray) {
        If ($IP -match "(\b(([01]?\d?\d|2[0-4]\d|25[0-5])\.){3}([01]?\d?\d|2[0-4]\d|25[0-5])\b)") {
            $DNSCheck = 'Pass' 
        }
        else {
            Write-Output $IP "is an invalid IP Address. Please try again" 
            $DNSCheck = $Null
            Return
        }
    }

    #Set Logging Location
    $Script:LogFile = $LogDir + "\DNSInfo.log"

    #Set Backup Location
    $BackupFile = $BackupDir + "\DNSInfo_Backup.txt"

    #Update console with progress
    Write-Output ""
    Write-Output "-----------------------------"
    Write-Output "Running Set-DNSInfo....."
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
    "-----------------------------" >> $LogFile
    "Current DNS Address Information" >> $LogFile
    "-----------------------------" >> $LogFile
   
    #Write current DNS Information to log
    Get-DNSInfo >> $LogFile
    $NewLogLine >> $LogFile 

    #Get Array from Get-DNSInfo
    $DNSArray = Get-DNSInfo

    #Continue if DNS Addresses passed to script are valid
    If ($DNSCheck -eq 'Pass') {
        
        #Backup Existing DNS Information to a txt File. Create new file if one exists 
        If ($Backup -eq $True) {
            If (Test-Path $BackupFile) {
                $DNSArray.DNS_Addresses > $BackupDir"\DNSinfo_Backup_"$LogTimeStamp".txt"  
            }
            else {
                $DNSArray.DNS_Addresses > $BackupFile
            }
        
        }

        #Update log if user opted to skip checing if the IP was obtained from a DHCP Server
        If ($SkipDHCPCheck -eq $True) {
            "-----------------------------" >> $LogFile
            "DHCP Prompt?" >> $LogFile
            "-----------------------------" >> $LogFile
            "Parameter passed to skip DHCP Check" >> $LogFile
            $NewLogLine >> $LogFile 
        }
    
        #Check if DHCP is enabled on Domain Network Adapter
        ForEach ($DNSItem in $DNSArray) {
            If ($DNSItem.DHCP_Enabled -eq 'True' -and $SkipDHCPCheck -eq $False) { 

                #Ask user if they want to continue with the operation
                Do {
                    $DHCPPrompt = Read-Host "This is a DHCP Client. Are you sure you want to continue? (Y = Yes, N = No)"
                    Switch ($DHCPPrompt) { 
                        #Answer No
                        n {
                            #Update DHCPOtopionOk Variable
                            $DHCPOptionOk = $True

                            #Write progress to log
                            Write-Output "Terminated by user at ConfirmOperationDHCP"
                            "-----------------------------" >> $LogFile
                            "DHCP Prompt?" >> $LogFile
                            "-----------------------------" >> $LogFile
                            "Terminated by user at ConfirmOperationDHCP" >> $LogFile
                            $NewLogLine >> $LogFile 
                            Return
                        }
                        #Answer Yes
                        y {
                            #Update DHCPOtopionOk Variable
                            $DHCPOptionOk = $True
                        
                            #Write progress to log
                            "-----------------------------" >> $LogFile
                            "DHCP Prompt?" >> $LogFile
                            "-----------------------------" >> $LogFile
                            "Warning Accepted by user at ConfirmOperationDHCP" >> $LogFile
                            $NewLogLine >> $LogFile 
                        }
                        #Retry on Invalid Option
                        Default {
                            $DHCPOptionOk = $False
                            Write-Output "Invalid Option"
                        } 
                    } 
                }
                Until ($DHCPOptionOk)

                #Display CUrrent DNS Information
                Write-Output ""
                Write-Output "-----------------------------"
                Write-Output "Getting Current DNS Information....."
                Write-Output "-----------------------------"
                Write-Output $DNSArray
            }

            If ($DNSItem.DHCP_Enabled -eq 'True' -and $SkipDHCPCheck -eq $True) {
                #Update DHCPOtopionOk Variable
                $DHCPOptionOk = $True
                        
                #Write progress to log
                "-----------------------------" >> $LogFile
                "DHCP Prompt?" >> $LogFile
                "-----------------------------" >> $LogFile
                "SkipDHCPCheck Param passed to script by user" >> $LogFile
                $NewLogLine >> $LogFile
            }

            #Display New DNS Information passed to Function
            Write-Output ""
            Write-Output "-----------------------------"
            Write-Output "Setting New DNS Addresses....."
            Write-Output "-----------------------------"    
            Write-Output $NewDNSArray

            #Write progress to log
            "-----------------------------" >> $LogFile
            "DNS Addresses specified as parameters" >> $LogFile
            "-----------------------------" >> $LogFile
            $NewDNSArray >> $LogFile

            #Call Set-DNSInfoAddress Function to set the new DNS Addess/es on the Client
            Set-DNSInfoAddress -NewDNS $NewDNSArray

            #Write progress to log
            "DNS Servers Updated" >> $LogFile
        }

    }
    else {
        #Display error of incorrect IP format used
        Write-Output "Invalid IP address passed. Please re-run the Set-DNSInfo Function"

        #Write progress to log
        "-----------------------------" >> $LogFile
        "DNS Addresses specified as parameters" >> $LogFile
        "-----------------------------" >> $LogFile
        $NewDNSArray >> $LogFile
        "Invalid IP address passed"
    }

}
Function Set-DNSInfoAddress {
    <#

.DESCRIPTION
Function to Set DNS Addresses for the Domain Connected Adapter. No prompts. Suggest using Set-DNSInfo instead

.EXAMPLE
Set-DNSInfoAddress "1.1.1.1,2.2.2.2,3.3.3.3,4.4.4.4"
#>
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $True)]
        [String[]]$NewDNS
    )

    #Check all IPs are valid
    ForEach ($IP in $NewDNSArray) {
        If ($IP -match "(\b(([01]?\d?\d|2[0-4]\d|25[0-5])\.){3}([01]?\d?\d|2[0-4]\d|25[0-5])\b)") {
            write-host $IP "is valid" 
        } else {
            write-host $IP "is an invalid IP Address. Please try again" 
        }
    }

    #Get Domain Connected adapter from Get-DNSInfo Function
    Get-DNSInfo -NoOutput 

    #Select Domain Adapter
    $DNSAdapterIndex = $DomainAdapter.InterfaceIndex

    #Update CLient DNS Address/es
    Set-DnsClientServerAddress -InterfaceIndex $DNSAdapterIndex -ServerAddresses $NewDNSArray
}