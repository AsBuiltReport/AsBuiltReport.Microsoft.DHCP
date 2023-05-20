function Get-AbrDHCPReport {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Microsoft AD DHCP Servers Scopes Server Options from DHCP Servers
    .DESCRIPTION

    .NOTES
        Version:        0.1.0
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
            $Domain
            )

    begin {
        Write-PscriboMessage "Discovering DHCP Servers Scope Server Options information."
    }

    process {
        if ($Domain) {
            try {
                $DomainDHCPs = $DHCPinDomain | Where-Object {$_.DnsName.split(".", 2)[1] -eq $Domain.DNSRoot} | Select-Object -ExpandProperty DnsName | Where-Object {$_ -notin $Options.Exclude.DCs}
                if ($DomainDHCPs) {
                    Section -Style Heading2 "$($Domain.DNSRoot.ToString().ToUpper())" {
                        Paragraph "The following section provides a summary of the Dynamic Host Configuration Protocol."
                        $DHCPinDC = $DHCPinDomain | Where-Object {$_.DnsName.split(".", 2)[1] -eq $Domain.DNSRoot -and $_.DnsName -notin $Options.Exclude.DCs}
                        Get-AbrADDHCPInfrastructure -Domain $Domain.DNSRoot
                        Section -Style Heading3 "IPv4 Scope Configuration" {
                            Paragraph "The following sections detail the configuration of the ipv4 scopes within domain $($Domain.DNSRoot)."
                            BlankLine
                            try {
                                Get-AbrADDHCPv4Statistic -Domain $Domain.DNSRoot
                            }
                            catch {
                                Write-PScriboMessage -IsWarning "Error: Retreiving DHCP Server IPv4 Statistics from  $($Domain.DNSRoot.ToString().ToUpper())."
                                Write-PScriboMessage -IsWarning "$($_.Exception.Message) (IPv4 DHCP Server Statistics)"
                            }
                            foreach ($DHCPServer in $DomainDHCPs){
                                if (Test-Connection -ComputerName $DHCPServer -Quiet -Count 1) {
                                    $TempCIMSession = New-CIMSession $DHCPServer -Credential $Credential -Authentication $Options.PSDefaultAuthentication -ErrorAction Stop
                                    $DHCPScopes =  Get-DhcpServerv4Scope -CimSession $TempCIMSession -ComputerName $DHCPServer | Select-Object -ExpandProperty ScopeId
                                    if ($DHCPScopes) {
                                        try {
                                            Get-AbrADDHCPv4Scope -Domain $Domain.DNSRoot -Server $DHCPServer
                                        }
                                        catch {
                                            Write-PScriboMessage -IsWarning "$($_.Exception.Message) (IPv4 DHCP Server Scope information)"
                                        }
                                        if ($InfoLevel.DHCP -ge 2) {
                                            try {
                                                Get-AbrADDHCPv4ScopeServerSetting -Domain $Domain.DNSRoot -Server $DHCPServer
                                                if ($DHCPScopes) {
                                                    Section -Style Heading4 "Scope Options" {
                                                        Paragraph "The following sections detail the configuration of the ipv4 per scope server option."
                                                        foreach ($Scope in $DHCPScopes) {
                                                            try {
                                                                Get-AbrADDHCPv4PerScopeSetting -Domain $Domain.DNSRoot -Server $DHCPServer -Scope $Scope
                                                            }
                                                            catch {
                                                                Write-PScriboMessage -IsWarning "Error: Retreiving DHCP Server IPv4 Scope configuration from $($DHCPServer.split(".", 2)[0])."
                                                                Write-PScriboMessage -IsWarning "$($_.Exception.Message) (IPv4 DHCP Server Scope configuration)"
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
                            }
                        }
                        Section -Style Heading3 "IPv6 Scope Configuration" {
                            Paragraph "The following section provides a IPv6 configuration summary of the Dynamic Host Configuration Protocol."
                            BlankLine
                            try {
                                Get-AbrADDHCPv6Statistic -Domain $Domain.DNSRoot
                            }
                            catch {
                                Write-PScriboMessage -IsWarning "Error: Retreiving DHCP Server IPv6 Statistics from $($Domain.DNSRoot.ToString().ToUpper())."
                                Write-PScriboMessage -IsWarning "$($_.Exception.Message) (IPv6 DHCP Server IPv6 Statistics)"
                            }
                            foreach ($DHCPServer in $DomainDHCPs){
                                if (Test-Connection -ComputerName $DHCPServer -Quiet -Count 1) {
                                    $TempCIMSession = New-CIMSession $DHCPServer -Credential $Credential -Authentication $Options.PSDefaultAuthentication -ErrorAction Stop
                                    $DHCPScopes =  Get-DhcpServerv6Scope -CimSession $TempCIMSession -ComputerName $DHCPServer | Select-Object -ExpandProperty Prefix
                                    Write-PScriboMessage "Discovering Dhcp Server IPv6 Scopes from $DHCPServer"
                                    if ($DHCPScopes) {
                                        try {
                                            Get-AbrADDHCPv6Scope -Domain $Domain.DNSRoot -Server $DHCPServer
                                        }
                                        catch {
                                            Write-PscriboMessage -IsWarning "$($_.Exception.Message) (IPv6 DHCP Scope Information)"
                                        }
                                        if ($InfoLevel.DHCP -ge 2) {
                                            try {
                                                Get-AbrADDHCPv6ScopeServerSetting -Domain $Domain.DNSRoot -Server $DHCPServer
                                                if ($DHCPScopes) {
                                                    Section -Style Heading4 "Scope Options" {
                                                        Paragraph "The following section provides a summary 6 Scope Server Options information."
                                                        BlankLine
                                                        foreach ($Scope in $DHCPScopes) {
                                                            try {
                                                                Get-AbrADDHCPv6PerScopeSetting -Domain $Domain.DNSRoot -Server $DHCPServer -Scope $Scope
                                                            }
                                                            catch {
                                                                Write-PScriboMessage -IsWarning "Error: Retreiving DHCP Server IPv6 Scope configuration from $($DHCPServerr.split(".", 2)[0])."
                                                                Write-PScriboMessage -IsWarning "$($_.Exception.Message) (IPv6 Per DHCP Scope configuration)"
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
                Write-PScriboMessage -IsWarning "$($_.Exception.Message) ($($Domain.DNSRoot.ToString().ToUpper()) Domain DHCP Configuration)"
            }
        }
    }

    end {}

}