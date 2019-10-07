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

    1.0.1   07/10/2019  Ben Whitmore
    Updated Validate Set for Set-DNSInfo Parameters

    1.0.0   06/10/2019  Ben Whitmore
    Initial Release
#>

Function Get-DNSInfo {
    <#
	.EXTERNALHELP DNSInfo.psm1-Help.xml
#>
    [CmdletBinding()]
    Param
    (
        [String]$NoOutput = 'False'
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
        If ($NoOutput -eq 'False') {
            $DNSArray
        }
    }
    else {
        If ($NoOutput -eq 'False') {
            write-host "This host is not connected to a Domain"
        }
    }
}

Function Set-DNSInfo {
    <#
	.EXTERNALHELP DNSInfo.psm1-Help.xml
#>

    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $True)]
        [ValidateScript( { $_ -match [IPAddress]$_ })] 
        [String[]]$NewDNS,
        [ValidateSet('True', 'False')] 
        [String]$Backup = 'False',
        [ValidateSet('True', 'False')] 
        [String]$ResetLog = 'False',
        [String]$LogDir = $ENV:TEMP,
        [String]$BackupDir = $ENV:TEMP,
        [ValidateSet('True', 'False')] 
        [String]$SkipDHCPCheck = 'False'
    )

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
    If ($ResetLog -eq 'True') {
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

    #Backup Existing DNS Information to a txt File. Create new file if one exists 
    If ($Backup -eq 'True') {
        If (Test-Path $BackupFile) {
            $DNSArray.DNS_Addresses > $BackupDir"\DNSinfo_Backup_"$LogTimeStamp".txt"  
        }
        else {
            $DNSArray.DNS_Addresses > $BackupFile
        }
        
    }

    #Update log if user opted to skip checing if the IP was obtained from a DHCP Server
    If ($SkipDHCPCheck -eq "True") {
                                
        Write-Output "Do Something. SkipDHCPCHeck"
        "-----------------------------" >> $LogFile
        "DHCP Prompt?" >> $LogFile
        "-----------------------------" >> $LogFile
        "Parameter passed to skip DHCP Check" >> $LogFile
        $NewLogLine >> $LogFile 
    }
    
    #Check if DHCP is enabled on Domain Network Adapter
    ForEach ($DNSItem in $DNSArray) {
        If ($DNSItem.DHCP_Enabled -eq 'True' -and $SkipDHCPCheck -eq 'False') { 

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
                        Exit
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

        #Display New DNS Information passed to Function
        Write-Output ""
        Write-Output "-----------------------------"
        Write-Output "Setting New DNS Addresses....."
        Write-Output "-----------------------------"    
        Write-Output $NewDNS

        #Write progress to log
        "-----------------------------" >> $LogFile
        "DNS Addresses specified as parameters" >> $LogFile
        "-----------------------------" >> $LogFile
        $NewDNS >> $LogFile

        #Call Set-DNSInfoAddress Function to set the new DNS Addess/es on the Client
        Set-DNSInfoAddress -NewDNS $NewDNS

        #Write progress to log
        "DNS Servers Updated" >> $LogFile
    }
}

Function Set-DNSInfoAddress {
    <#
	.EXTERNALHELP DNSInfo.psm1-Help.xml
#>
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $True)]
        [ValidateScript( { $_ -match [IPAddress]$_ })] 
        [String[]]$NewDNS
    )

    #Get Domain Connected adapter from Get-DNSInfo Function
    Get-DNSInfo -NoOutput 'True' 

    #Select Domain Adapter
    $DNSAdapterIndex = $DomainAdapter.InterfaceIndex

    #Update CLient DNS Address/es
    Set-DnsClientServerAddress -InterfaceIndex $DNSAdapterIndex -ServerAddresses $NewDNS 
}

