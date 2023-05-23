function Invoke-AsBuiltReport.Microsoft.DHCP {
    <#
    .SYNOPSIS
        PowerShell script to document the configuration of Microsoft DHCP in Word/HTML/Text formats
    .DESCRIPTION
        Documents the configuration of Microsoft DHCP in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.1.0
        Author:         Jonathan Colon
        Twitter:        @jcolonfzenpr
        Github:         rebelinux
        Credits:        Iain Brighton (@iainbrighton) - PScribo module

    .LINK
        https://github.com/AsBuiltReport/AsBuiltReport.Microsoft.DHCP
    #>

	# Do not remove or add to these parameters
    param (
        [String[]] $Target,
        [PSCredential] $Credential
    )

    Write-PScriboMessage -IsWarning "Please refer to the AsBuiltReport.Microsoft.DHCP github website for more detailed information about this project."
    Write-PScriboMessage -IsWarning "Do not forget to update your report configuration file after each new release."
    Write-PScriboMessage -IsWarning "Documentation: https://github.com/AsBuiltReport/AsBuiltReport.Microsoft.DHCP"
    Write-PScriboMessage -IsWarning "Issues or bug reporting: https://github.com/AsBuiltReport/AsBuiltReport.Microsoft.DHCP/issues"

    Try {
        $InstalledVersion = Get-Module -ListAvailable -Name AsBuiltReport.Microsoft.DHCP -ErrorAction SilentlyContinue | Sort-Object -Property Version -Descending | Select-Object -First 1 -ExpandProperty Version

        if ($InstalledVersion) {
            Write-PScriboMessage -IsWarning "AsBuiltReport.Microsoft.DHCP $($InstalledVersion.ToString()) is currently installed."
            $LatestVersion = Find-Module -Name AsBuiltReport.Microsoft.DHCP -Repository PSGallery -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Version
            if ($LatestVersion -gt $InstalledVersion) {
                Write-PScriboMessage -IsWarning "AsBuiltReport.Microsoft.DHCP $($LatestVersion.ToString()) is available."
                Write-PScriboMessage -IsWarning "Run 'Update-Module -Name AsBuiltReport.Microsoft.DHCP -Force' to install the latest version."
            }
        }
    } Catch {
            Write-PscriboMessage -IsWarning $_.Exception.Message
    }

    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())

    if (-Not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {

        throw "The requested operation requires elevation: Run PowerShell console as administrator"
    }


    #Validate Required Modules and Features
    $OSType = (Get-ComputerInfo).OsProductType
    if ($OSType -eq 'WorkStation') {
        Get-RequiredFeature -Name 'Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0' -OSType $OSType
        Get-RequiredFeature -Name 'Rsat.DHCP.Tools~~~~0.0.1.0' -OSType $OSType

    }
    if ($OSType -eq 'Server' -or $OSType -eq 'DomainController') {
        Get-RequiredFeature -Name RSAT-AD-PowerShell -OSType $OSType
        Get-RequiredFeature -Name RSAT-DHCP -OSType $OSType
    }


    # Import Report Configuration
    $Report = $ReportConfig.Report
    $InfoLevel = $ReportConfig.InfoLevel
    $Options = $ReportConfig.Options

    # Used to set values to TitleCase where required
    $TextInfo = (Get-Culture).TextInfo

    #region foreach loop
    foreach ($System in $Target) {
        try {
            $TempCIMSession = New-CIMSession -ComputerName $System -Credential $Credential -Authentication $Options.PSDefaultAuthentication -ErrorAction Stop
            $ADSystem = Get-ADForest -ErrorAction Stop -Credential $Credential
        } catch {
            throw "Unable to discover Forest information from $System"
        }

        try {
            $DHCPinDomain = Get-DhcpServerInDC
        } catch {
            throw "Unable to get DHCP discovery from $System"
        }

        $script:ForestInfo =  $ADSystem.RootDomain.toUpper()
        [array]$RootDomains = $ADSystem.RootDomain
        [array]$ChildDomains = $ADSystem.Domains | Where-Object {$_ -ne $RootDomains}
        [string]$OrderedDomains = $RootDomains + $ChildDomains

        #---------------------------------------------------------------------------------------------#
        #                                 DHCP Section                                                #
        #---------------------------------------------------------------------------------------------#

        if ($InfoLevel.DHCP -ge 1 -and $DHCPinDomain ) {
            foreach ($Domain in ($OrderedDomains.split(" "))) {
                if ($Domain -notin $Options.Exclude.Domains) {
                    try {
                        $DomainInfo = Get-ADDomain $Domain -ErrorAction Stop
                        if ($Domain) {
                            try {
                                $DomainDHCPs = $DHCPinDomain | Where-Object {$_.DnsName.split(".", 2)[1] -eq $DomainInfo.DNSRoot} | Select-Object -ExpandProperty DnsName | Where-Object {$_ -notin $Options.Exclude.DCs}
                                if ($DomainDHCPs) {
                                    Section -Style Heading1 "$($DomainInfo.DNSRoot.ToString().ToUpper())" {
                                        Paragraph "The following section provides a summary of the Dynamic Host Configuration Protocol."
                                        $DHCPinDC = $DHCPinDomain | Where-Object {$_.DnsName.split(".", 2)[1] -eq $DomainInfo.DNSRoot -and $_.DnsName -notin $Options.Exclude.DCs}
                                        Get-AbrADDHCPInfrastructure -Domain $DomainInfo.DNSRoot
                                        Section -Style Heading2 "IPv4 Information" {
                                            Paragraph "The following sections detail the configuration of the ipv4 scopes within domain $($DomainInfo.DNSRoot)."
                                            BlankLine
                                            try {
                                                Get-AbrADDHCPv4Statistic -Domain $DomainInfo.DNSRoot
                                            }
                                            catch {
                                                Write-PScriboMessage -IsWarning "Error: Retreiving DHCP Server IPv4 Statistics from  $($DomainInfo.DNSRoot.ToString().ToUpper())."
                                                Write-PScriboMessage -IsWarning "$($_.Exception.Message) (IPv4 DHCP Server Statistics)"
                                            }
                                            try {
                                                Get-AbrADDHCPv4FilterStatus -Domain $DomainInfo.DNSRoot
                                            }
                                            catch {
                                                Write-PScriboMessage -IsWarning "Error: Retreiving DHCP Server IPv4 Filter Status from  $($DomainInfo.DNSRoot.ToString().ToUpper())."
                                                Write-PScriboMessage -IsWarning "$($_.Exception.Message) (IPv4 DHCP Server Filter Status)"
                                            }
                                            foreach ($DHCPServer in $DomainDHCPs){
                                                if (Test-Connection -ComputerName $DHCPServer -Quiet -Count 2) {
                                                    $TempCIMSession = New-CIMSession $DHCPServer -Credential $Credential -Authentication $Options.PSDefaultAuthentication -ErrorAction Stop
                                                    $DHCPScopes =  Get-DhcpServerv4Scope -CimSession $TempCIMSession -ComputerName $DHCPServer | Select-Object -ExpandProperty ScopeId
                                                    if ($DHCPScopes) {
                                                        Section -Style Heading3 "$($DHCPServer.ToUpper().split(".", 2)[0])" {
                                                            try {
                                                                Get-AbrADDHCPv4Scope -Domain $DomainInfo.DNSRoot -Server $DHCPServer
                                                            }
                                                            catch {
                                                                Write-PScriboMessage -IsWarning "$($_.Exception.Message) (IPv4 DHCP Server Scope information)"
                                                            }
                                                            if ($InfoLevel.DHCP -ge 2) {
                                                                try {
                                                                    Get-AbrADDHCPv4ScopeServerSetting -Domain $DomainInfo.DNSRoot -Server $DHCPServer
                                                                    if ($DHCPScopes) {
                                                                        Section -Style Heading4 "Scope Configuration" {
                                                                            Paragraph "The following sections detail the configuration of the ipv4 per scope configuration."
                                                                            foreach ($Scope in $DHCPScopes) {
                                                                                Section -Style Heading5 $Scope {
                                                                                    try {
                                                                                        Get-AbrADDHCPv4PerScopeProperty -Server $DHCPServer -Scope $Scope
                                                                                    }
                                                                                    catch {
                                                                                        Write-PScriboMessage -IsWarning "Error: Retreiving DHCP Server IPv4 Scope Exclusion from $($DHCPServer.split(".", 2)[0])."
                                                                                        Write-PScriboMessage -IsWarning "$($_.Exception.Message) (IPv4 DHCP Server Scope Exclusion)"
                                                                                    }
                                                                                    try {
                                                                                        Get-AbrADDHCPv4PerScopeExclusion -Server $DHCPServer -Scope $Scope
                                                                                    }
                                                                                    catch {
                                                                                        Write-PScriboMessage -IsWarning "Error: Retreiving DHCP Server IPv4 Scope Exclusion from $($DHCPServer.split(".", 2)[0])."
                                                                                        Write-PScriboMessage -IsWarning "$($_.Exception.Message) (IPv4 DHCP Server Scope Exclusion)"
                                                                                    }
                                                                                    try {
                                                                                        Get-AbrADDHCPv4PerScopeReservation -Server $DHCPServer -Scope $Scope
                                                                                    }
                                                                                    catch {
                                                                                        Write-PScriboMessage -IsWarning "Error: Retreiving DHCP Server IPv4 Scope reservation from $($DHCPServer.split(".", 2)[0])."
                                                                                        Write-PScriboMessage -IsWarning "$($_.Exception.Message) (IPv4 DHCP Server Scope reservation)"
                                                                                    }

                                                                                    try {
                                                                                        Get-AbrADDHCPv4PerScopeOption -Server $DHCPServer -Scope $Scope
                                                                                    }
                                                                                    catch {
                                                                                        Write-PScriboMessage -IsWarning "Error: Retreiving DHCP Server IPv4 Scope options from $($DHCPServer.split(".", 2)[0])."
                                                                                        Write-PScriboMessage -IsWarning "$($_.Exception.Message) (IPv4 DHCP Server Scope options)"
                                                                                    }

                                                                                    try {
                                                                                        Get-AbrADDHCPv4PerScopePolicy -Server $DHCPServer -Scope $Scope
                                                                                    }
                                                                                    catch {
                                                                                        Write-PScriboMessage -IsWarning "Error: Retreiving DHCP Server IPv4 Scope options from $($DHCPServer.split(".", 2)[0])."
                                                                                        Write-PScriboMessage -IsWarning "$($_.Exception.Message) (IPv4 DHCP Server Scope options)"
                                                                                    }
                                                                                }
                                                                            }
                                                                        }
                                                                    }
                                                                }
                                                                catch {
                                                                    Write-PScriboMessage -IsWarning "$($_.Exception.Message) (IPv4 DHCP Scope Server Options)"
                                                                }
                                                            }

                                                            if ($TempCIMSession) {
                                                                Write-PscriboMessage "Clearing CIM Session $($TempCIMSession.Id)"
                                                                Remove-CIMSession -CimSession $TempCIMSession
                                                            }
                                                        }
                                                    }
                                                } else {Write-PScriboMessage -IsWarning "Unable to connect to $($DHCPServer). Removing Server from report"}
                                            }
                                        }
                                        Section -Style Heading2 "IPv6 Information" {
                                            Paragraph "The following section provides a IPv6 configuration summary of the Dynamic Host Configuration Protocol."
                                            BlankLine
                                            try {
                                                Get-AbrADDHCPv6Statistic -Domain $DomainInfo.DNSRoot
                                            }
                                            catch {
                                                Write-PScriboMessage -IsWarning "Error: Retreiving DHCP Server IPv6 Statistics from $($DomainInfo.DNSRoot.ToString().ToUpper())."
                                                Write-PScriboMessage -IsWarning "$($_.Exception.Message) (IPv6 DHCP Server IPv6 Statistics)"
                                            }
                                            foreach ($DHCPServer in $DomainDHCPs){
                                                if (Test-Connection -ComputerName $DHCPServer -Quiet -Count 2) {
                                                    $TempCIMSession = New-CIMSession $DHCPServer -Credential $Credential -Authentication $Options.PSDefaultAuthentication -ErrorAction Stop
                                                    $DHCPScopes =  Get-DhcpServerv6Scope -CimSession $TempCIMSession -ComputerName $DHCPServer | Select-Object -ExpandProperty Prefix
                                                    Write-PScriboMessage "Discovering Dhcp Server IPv6 Scopes from $DHCPServer"
                                                    if ($DHCPScopes) {
                                                        Section -Style Heading3 "$($DHCPServer.ToUpper().split(".", 2)[0])" {
                                                            try {
                                                                Get-AbrADDHCPv6Scope -Domain $DomainInfo.DNSRoot -Server $DHCPServer
                                                            }
                                                            catch {
                                                                Write-PscriboMessage -IsWarning "$($_.Exception.Message) (IPv6 DHCP Scope Information)"
                                                            }
                                                            if ($InfoLevel.DHCP -ge 2) {
                                                                try {
                                                                    Get-AbrADDHCPv6ScopeServerSetting -Domain $DomainInfo.DNSRoot -Server $DHCPServer
                                                                    if ($DHCPScopes) {
                                                                        Section -Style Heading4 "Scope Configuration" {
                                                                            Paragraph "The following section provides a summary 6 Scope Server Options information."
                                                                            BlankLine
                                                                            foreach ($Scope in $DHCPScopes) {
                                                                                Section -Style Heading5 $Scope {
                                                                                    try {
                                                                                        Get-AbrADDHCPv6PerScopeExclusion -Server $DHCPServer -Scope $Scope
                                                                                    }
                                                                                    catch {
                                                                                        Write-PScriboMessage -IsWarning "Error: Retreiving DHCP Server IPv6 Scope Exclusion from $($DHCPServer.split(".", 2)[0])."
                                                                                        Write-PScriboMessage -IsWarning "$($_.Exception.Message) (IPv6 DHCP Server Scope Exclusion)"
                                                                                    }
                                                                                    try {
                                                                                        Get-AbrADDHCPv6PerScopeReservation -Server $DHCPServer -Scope $Scope
                                                                                    }
                                                                                    catch {
                                                                                        Write-PScriboMessage -IsWarning "Error: Retreiving DHCP Server IPv6 Scope reservation from $($DHCPServer.split(".", 2)[0])."
                                                                                        Write-PScriboMessage -IsWarning "$($_.Exception.Message) (IPv6 DHCP Server Scope reservation)"
                                                                                    }
                                                                                    try {
                                                                                        Get-AbrADDHCPv6PerScopeOption -Server $DHCPServer -Scope $Scope
                                                                                    }
                                                                                    catch {
                                                                                        Write-PScriboMessage -IsWarning "Error: Retreiving DHCP Server IPv6 Scope options from $($DHCPServer.split(".", 2)[0])."
                                                                                        Write-PScriboMessage -IsWarning "$($_.Exception.Message) (IPv6 DHCP Server Scope options)"
                                                                                    }
                                                                                }
                                                                            }
                                                                        }
                                                                    }
                                                                }
                                                                catch {
                                                                    Write-PScriboMessage -IsWarning "$($_.Exception.Message) (IPv6 DHCP Scope Server Options)"
                                                                }
                                                            }
                                                        }
                                                    }
                                                } else {Write-PScriboMessage -IsWarning "Unable to connect to $($DHCPServer). Removing Server from report"}
                                            }

                                            if ($TempCIMSession) {
                                                Write-PscriboMessage "Clearing CIM Session $($TempCIMSession.Id)"
                                                Remove-CIMSession -CimSession $TempCIMSession
                                            }
                                        }
                                    }
                                }
                            }
                            catch {
                                Write-PScriboMessage -IsWarning "$($_.Exception.Message) ($($DomainInfo.DNSRoot.ToString().ToUpper()) Domain DHCP Configuration)"
                            }                        }
                    } catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
                        Write-PScriboMessage -IsWarning "Unable to retreive $($Domain) information. Removing Domain from report"
                    }
                }
            }
        }#endregion DHCP Section

        if ($TempCIMSession) {
            Write-PscriboMessage "Clearing CIM Session $($TempCIMSession.Id)"
            Remove-CIMSession -CimSession $TempCIMSession
        }
	}
	#endregion foreach loop
}
