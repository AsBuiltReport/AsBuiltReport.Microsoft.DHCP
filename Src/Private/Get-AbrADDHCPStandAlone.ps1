function Get-AbrADDHCPStandAlone {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Microsoft DHCP information from an StandAlone Server
    .DESCRIPTION

    .NOTES
        Version:        0.2.0
        Author:         Jonathan Colon
        Twitter:        @jcolonfzenpr
        Github:         rebelinux
    .EXAMPLE

    .LINK

    #>
    [CmdletBinding()]
    param (
        [Parameter (
            Position = 0,
            Mandatory)]
            [string]
            $Domain
    )

    begin {
        Write-PscriboMessage "Discovering DHCP Server information from $($System.ToString().ToUpper())."
    }

    process {
        try {
            if ($DomainDHCPs) {
                Section -Style Heading1 "$($System.ToString().ToUpper().Split(".", 2)[0])" {
                    Paragraph "The following section provides a summary of the Dynamic Host Configuration Protocol."
                    $script:DHCPinDC = $DomainDHCPs
                    Get-AbrADDHCPInfrastructure -Domain $Domain.split(".", 2).ToUpper()[0]
                    Section -Style Heading2 "IPv4 Information" {
                        Paragraph "The following sections detail the configuration of the IPv4 scopes within domain $($Domain)."
                        BlankLine
                        try {
                            Get-AbrADDHCPv4Statistic -Domain $Domain
                        }
                        catch {
                            Write-PScriboMessage -IsWarning "Error: Retreiving DHCP Server IPv4 Statistics from  $($Domain.ToString().ToUpper())."
                            Write-PScriboMessage -IsWarning "$($_.Exception.Message) (IPv4 DHCP Server Statistics)"
                        }
                        try {
                            Get-AbrADDHCPv4FilterStatus -Domain $Domain
                        }
                        catch {
                            Write-PScriboMessage -IsWarning "Error: Retreiving DHCP Server IPv4 Filter Status from  $($Domain.ToString().ToUpper())."
                            Write-PScriboMessage -IsWarning "$($_.Exception.Message) (IPv4 DHCP Server Filter Status)"
                        }
                        foreach ($DHCPServer in $DomainDHCPs){
                            if (Test-Connection -ComputerName $DHCPServer -Quiet -Count 2) {
                                $TempCIMSession = New-CIMSession $DHCPServer -Credential $Credential -Authentication $Options.PSDefaultAuthentication -ErrorAction Stop
                                $DHCPScopes =  Get-DhcpServerv4Scope -CimSession $TempCIMSession -ComputerName $DHCPServer | Select-Object -ExpandProperty ScopeId
                                if ($DHCPScopes) {
                                    Section -Style Heading3 "$($DHCPServer.ToUpper().split(".", 2)[0])" {
                                        try {
                                            Get-AbrADDHCPv4Scope -Domain $Domain -Server $DHCPServer
                                        }
                                        catch {
                                            Write-PScriboMessage -IsWarning "$($_.Exception.Message) (IPv4 DHCP Server Scope information)"
                                        }
                                        if ($InfoLevel.DHCP -ge 2) {
                                            try {
                                                Get-AbrADDHCPv4ScopeServerSetting -Domain $Domain -Server $DHCPServer
                                                if ($DHCPScopes) {
                                                    Section -Style Heading4 "Scope Configuration" {
                                                        Paragraph "The following sections detail the configuration of the IPv4 per scope configuration."
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
                            Get-AbrADDHCPv6Statistic -Domain $Domain
                        }
                        catch {
                            Write-PScriboMessage -IsWarning "Error: Retreiving DHCP Server IPv6 Statistics from $($Domain.ToString().ToUpper())."
                            Write-PScriboMessage -IsWarning "$($_.Exception.Message) (IPv6 DHCP Server IPv6 Statistics)"
                        }
                        foreach ($DHCPServer in $DomainDHCPs){
                            if (Test-Connection -ComputerName $DHCPServer -Quiet -Count 2) {
                                $TempCIMSession = New-CIMSession $DHCPServer -Credential $Credential -Authentication $Options.PSDefaultAuthentication -ErrorAction Stop
                                $DHCPScopes =  Get-DhcpServerv6Scope -CimSession $TempCIMSession -ComputerName $DHCPServer | Select-Object -ExpandProperty Prefix
                                Write-PScriboMessage "Discovering DHCP Server IPv6 Scopes from $DHCPServer"
                                if ($DHCPScopes) {
                                    Section -Style Heading3 "$($DHCPServer.ToUpper().split(".", 2)[0])" {
                                        try {
                                            Get-AbrADDHCPv6Scope -Domain $Domain -Server $DHCPServer
                                        }
                                        catch {
                                            Write-PscriboMessage -IsWarning "$($_.Exception.Message) (IPv6 DHCP Scope Information)"
                                        }
                                        if ($InfoLevel.DHCP -ge 2) {
                                            try {
                                                Get-AbrADDHCPv6ScopeServerSetting -Domain $Domain -Server $DHCPServer
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
            Write-PScriboMessage -IsWarning "$($_.Exception.Message) ($($System.ToString().ToUpper()) Domain DHCP Configuration)"
        }
    }

    end {}

}