function Get-AbrADDHCPv4ScopeServerSetting {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Microsoft AD DHCP Servers Scopes Server Options from DHCP Servers
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
            $Domain,
            [string]
            $Server
    )

    begin {
        Write-PscriboMessage "Discovering DHCP Servers Scope Server Options information on $($Server.ToUpper().split(".", 2)[0])."
    }

    process {
        $DHCPScopeOptions = Get-DhcpServerv4OptionValue -CimSession $TempCIMSession -ComputerName $Server
        if ($DHCPScopeOptions) {
            Section -Style Heading3 "Global Server Options" {
                $OutObj = @()
                Write-PScriboMessage "Discovered '$(($DHCPScopeOptions | Measure-Object).Count)' DHCP scopes server opions on $($Server)."
                foreach ($Option in $DHCPScopeOptions) {
                    try {
                        Write-PscriboMessage "Collecting DHCP Server IPv4 Scope Server Option value $($Option.OptionId) from $($Server.split(".", 2)[0])"
                        $inObj = [ordered] @{
                            'Name' = $Option.Name
                            'Option Id' = $Option.OptionId
                            'Value' = $Option.Value
                            'Policy Name' = ConvertTo-EmptyToFiller $Option.PolicyName
                        }
                        $OutObj += [pscustomobject]$inobj
                    }
                    catch {
                        Write-PscriboMessage -IsWarning "$($_.Exception.Message) (DHCP scopes server opions item)"
                    }
                }
                $TableParams = @{
                    Name = "Scopes Server Options - $($Server.split(".", 2).ToUpper()[0])"
                    List = $false
                    ColumnWidths = 40, 15, 20, 25
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $OutObj | Sort-Object -Property 'Option Id' | Table @TableParams
                try {
                    $DHCPScopeOptions = Get-DhcpServerv4DnsSetting -CimSession $TempCIMSession -ComputerName $Server
                    if ($DHCPScopeOptions) {
                        Section -Style Heading4 "Global DNS Settings" {
                            Paragraph "The following table summarizes the DHCP server IPv4 global DNS settings."
                            BlankLine
                            $OutObj = @()
                            foreach ($Option in $DHCPScopeOptions) {
                                try {
                                    Write-PscriboMessage "Collecting DHCP Server IPv4 global DNS Settings value from $($Server)."
                                    $inObj = [ordered] @{
                                        'Dynamic Updates' = $Option.DynamicUpdates
                                        'DNS Suffix' = ConvertTo-EmptyToFiller $Option.DnsSuffix
                                        'Name Protection' = ConvertTo-EmptyToFiller $Option.NameProtection
                                        'Update DNS RR For Older Clients' = ConvertTo-EmptyToFiller $Option.UpdateDnsRRForOlderClients
                                        'Disable DNS PTR RR Update' = ConvertTo-EmptyToFiller $Option.DisableDnsPtrRRUpdate
                                        'Delete DNS RR On Lease Expiry' = ConvertTo-EmptyToFiller $Option.DeleteDnsRROnLeaseExpiry
                                    }
                                    $OutObj += [pscustomobject]$inobj
                                }
                                catch {
                                    Write-PscriboMessage -IsWarning "$($_.Exception.Message) (global DNS Settings Item)"
                                }
                            }

                            if ($HealthCheck.DHCP.BP) {
                                $OutObj | Where-Object { $_.'Dynamic Updates' -ne 'Always'} | Set-Style -Style Warning -Property 'Dynamic Updates'
                                $OutObj | Where-Object { $_.'Name Protection' -eq 'No'} | Set-Style -Style Warning -Property 'Name Protection'
                            }

                            $TableParams = @{
                                Name = "Global DNS Settings - $($Server.split(".", 2).ToUpper()[0])"
                                List = $true
                                ColumnWidths = 40, 60
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $OutObj | Table @TableParams
                            if ($HealthCheck.DHCP.BP -and ($OutObj | Where-Object { $_.'Dynamic Updates' -ne 'Always'}) -or ($OutObj | Where-Object { $_.'Name Protection' -eq 'No'})) {
                                Paragraph "Health Check:" -Bold -Underline
                                BlankLine
                                if ($HealthCheck.DHCP.BP -and ($OutObj | Where-Object { $_.'Dynamic Updates' -ne 'Always'})) {
                                    Paragraph {
                                        Text "Best Practice:" -Bold
                                        Text "'Always dynamically update DNS records' should be configured if secure dynamic DNS update is enabled and the domain controller is on the same host as the DHCP server."
                                    }
                                    BlankLine
                                }
                                if ($HealthCheck.DHCP.BP -and ($OutObj | Where-Object { $_.'Name Protection' -eq 'No'})) {
                                    Paragraph {
                                        Text "Best Practice:" -Bold
                                        Text "'Name Protection' should be configured to prevent Name Squating."
                                    }
                                }
                            }
                        }
                    }
                }
                catch {
                    Write-PscriboMessage -IsWarning "$($_.Exception.Message) (Scope DNS Setting Table)"
                }
            }
        }
    }

    end {}

}