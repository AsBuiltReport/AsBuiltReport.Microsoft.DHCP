function Get-AbrADDHCPInfrastructure {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Microsoft AD DHCP Servers from Domain Controller
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
            [string]
            $Domain
    )

    begin {
        Write-PscriboMessage "Discovering Active Directory DHCP Servers information on $($Domain.ToString().ToUpper())."
    }

    process {
        try {
            if ($DHCPinDC) {
                if ($Options.ServerDiscovery -eq "Domain") {
                    try {
                        Write-PScriboMessage "Discovered '$(($DHCPinDC | Measure-Object).Count)' DHCP Servers in forest $($Domain)."
                        Section -Style Heading2 'DHCP Servers in Domain' {
                            Paragraph "The following table summarises the DHCP servers information within $($Domain.ToString().ToUpper())."
                            BlankLine
                            $OutObj = @()
                            foreach ($DHCPServer in $DHCPinDC) {
                                if (Test-Connection -ComputerName $DHCPServer -Quiet -Count 2) {
                                    try {
                                        $TempCIMSession = New-CIMSession $DHCPServer -Credential $Credential -Authentication $Options.PSDefaultAuthentication -ErrorAction Stop
                                        Write-PScriboMessage "Collecting DHCP Server Setting information from $($DHCPServer.split(".", 2)[0])"
                                        $Setting = Get-DhcpServerSetting -CimSession $TempCIMSession -ComputerName $DHCPServer
                                        $inObj = [ordered] @{
                                            'DC Name' = $DHCPServer.Split(".", 2)[0]
                                            'IP Address' =  ($DHCPinDomain | Where-Object {$_.DnsName -eq $DHCPServer}).IPAddress
                                            'Domain Name' = $DHCPServer.Split(".", 2)[1]
                                            'Domain Joined' = ConvertTo-TextYN $Setting.IsDomainJoined
                                            'Authorized' = ConvertTo-TextYN $Setting.IsAuthorized
                                            'Conflict Detection Attempts' = $Setting.ConflictDetectionAttempts
                                        }
                                        $OutObj += [pscustomobject]$inobj
                                    }
                                    catch {
                                        Write-PscriboMessage -IsWarning "$($_.Exception.Message) (DHCP Servers in Domain Item)"
                                    }
                                    if ($TempCIMSession) {
                                        Write-PscriboMessage "Clearing CIM Session $($TempCIMSession.Id)"
                                        Remove-CIMSession -CimSession $TempCIMSession
                                    }
                                }
                            }
                            if ($HealthCheck.DHCP.BP) {
                                $OutObj | Where-Object { $_.'Conflict Detection Attempts' -eq 0} | Set-Style -Style Warning -Property 'Conflict Detection Attempts'
                                $OutObj | Where-Object { $_.'Authorized' -eq 'No'} | Set-Style -Style Warning -Property 'Authorized'
                            }

                            $TableParams = @{
                                Name = "DHCP Servers in Domain - $($Domain.ToString().ToUpper())"
                                List = $false
                                ColumnWidths = 20, 15, 20, 15, 15 ,15
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $OutObj | Sort-Object -Property 'DC Name' | Table @TableParams
                        }
                    } catch {
                        Write-PscriboMessage -IsWarning "$($_.Exception.Message) (DHCP Servers in Domain)"
                    }
                }
                try {
                    Section -Style Heading2 'Service Database' {
                        $OutObj = @()
                        foreach ($DHCPServer in $DHCPinDC) {
                            if (Test-Connection -ComputerName $DHCPServer -Quiet -Count 2) {
                                try {
                                    Write-PScriboMessage "Collecting DHCP Server database information from $($DHCPServer.split(".", 2)[0])"
                                    $TempCIMSession = New-CIMSession $DHCPServer -Credential $Credential -Authentication $Options.PSDefaultAuthentication -ErrorAction Stop
                                    $Setting = Get-DhcpServerDatabase -CimSession $TempCIMSession -ComputerName $DHCPServer
                                    $inObj = [ordered] @{
                                        'DC Name' = $DHCPServer.Split(".", 2)[0]
                                        'File Path' =  ConvertTo-EmptyToFiller $Setting.FileName
                                        'Backup Path' = ConvertTo-EmptyToFiller $Setting.BackupPath
                                        'Backup Interval' = switch ($Setting.BackupInterval) {
                                            "" {"--"; break}
                                            $NULL {"--"; break}
                                            default {"$($Setting.BackupInterval) min"}
                                        }
                                        'Logging Enabled' =  Switch ($Setting.LoggingEnabled) {
                                            ""  {"--"; break}
                                            $Null   {"--"; break}
                                            default {ConvertTo-TextYN $Setting.LoggingEnabled}
                                        }
                                    }
                                    $OutObj += [pscustomobject]$inobj
                                }
                                catch {
                                    Write-PscriboMessage -IsWarning "$($_.Exception.Message) (Service Database Item)"
                                }

                                if ($TempCIMSession) {
                                    Write-PscriboMessage "Clearing CIM Session $($TempCIMSession.Id)"
                                    Remove-CIMSession -CimSession $TempCIMSession
                                }
                            }
                        }

                        $TableParams = @{
                            Name = "Service Database - $($Domain.ToString().ToUpper())"
                            List = $false
                            ColumnWidths = 20, 28, 28, 12, 12
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $OutObj | Sort-Object -Property 'DC Name' | Table @TableParams
                    }
                }
                catch {
                    Write-PscriboMessage -IsWarning "$($_.Exception.Message) (Service Database Table)"
                }
                try {
                    Section -Style Heading2 'Dynamic DNS credentials' {
                        $OutObj = @()
                        foreach ($DHCPServer in $DHCPinDC) {
                            if (Test-Connection -ComputerName $DHCPServer -Quiet -Count 2) {
                                try{
                                    Write-PScriboMessage "Collecting DHCP Server Dynamic DNS Credentials information from $($DHCPServer.split(".", 2)[0])"
                                    $TempCIMSession = New-CIMSession $DHCPServer -Credential $Credential -Authentication $Options.PSDefaultAuthentication -ErrorAction Stop
                                    $Setting = Get-DhcpServerDnsCredential -CimSession $TempCIMSession -ComputerName $DHCPServer
                                    $inObj = [ordered] @{
                                        'DC Name' = $DHCPServer.Split(".", 2)[0]
                                        'User Name' =  ConvertTo-EmptyToFiller $Setting.UserName
                                        'Domain Name' = ConvertTo-EmptyToFiller $Setting.DomainName
                                    }
                                    $OutObj += [pscustomobject]$inobj
                                }
                                catch {
                                    Write-PscriboMessage -IsWarning "$($_.Exception.Message) (Dynamic DNS credentials Item)"
                                }

                                if ($TempCIMSession) {
                                    Write-PscriboMessage "Clearing CIM Session $($TempCIMSession.Id)"
                                    Remove-CIMSession -CimSession $TempCIMSession
                                }
                            }
                        }

                        if ($HealthCheck.DHCP.BP) {
                            $OutObj | Where-Object { $_.'User Name' -eq "--"} | Set-Style -Style Warning -Property 'User Name','Domain Name'
                        }

                        $TableParams = @{
                            Name = "Dynamic DNS Credentials - $($Domain.ToString().ToUpper())"
                            List = $false
                            ColumnWidths = 30, 30, 40
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $OutObj | Sort-Object -Property 'DC Name' | Table @TableParams
                        if ($HealthCheck.DHCP.BP -and ($OutObj | Where-Object { $_.'User Name' -eq "--"})) {
                            Paragraph "Health Check:" -Italic -Bold -Underline
                            BlankLine
                            Paragraph "Best Practice: Credentials for DNS update should be configured if secure dynamic DNS update is enabled and the domain controller is on the same host as the DHCP server." -Italic -Bold
                        }
                    }
                }
                catch {
                    Write-PscriboMessage -IsWarning "$($_.Exception.Message) (Dynamic DNS credentials Table)"
                }
            }
        }
        catch {
            Write-PscriboMessage -IsWarning "$($_.Exception.Message) (DHCP Infrastructure Section)"
        }
    }

    end {}

}