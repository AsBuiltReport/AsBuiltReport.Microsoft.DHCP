function Get-AbrADDHCPv4PerScopePolicy {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Microsoft AD DHCP Servers Policy from Domain Controller
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
            $Server,
            $Scope
    )

    begin {
        Write-PscriboMessage "Discovering Active Directory DHCP Servers Policy information on $($Domain.ToString().ToUpper())."
    }

    process {
        try {
            $DHCPPolicies = Get-DhcpServerv4Policy -CimSession $TempCIMSession -ComputerName $Server -ScopeId $Scope | Sort-Object -Property 'Name'
            if ($DHCPPolicies) {
                Section -ExcludeFromTOC -Style NOTOCHeading6 "Policies" {
                    $OutObj = @()
                    foreach ($DHCPPolicy in $DHCPPolicies) {
                        try {
                            Write-PscriboMessage "Collecting DHCP Server IPv4 $($DHCPPolicy.Name) policies from $($Server.split(".", 2)[0])"
                            $inObj = [ordered] @{
                                'Name' = $DHCPPolicy.Name
                                'Enabled' = ConvertTo-TextYN $DHCPPolicy.Enabled
                                'Scope Id' = $DHCPPolicy.ScopeId
                                'Processing Order' = $DHCPPolicy.ProcessingOrder
                                'Condition' = $DHCPPolicy.Condition
                                'Vendor Class' = Switch ([string]::IsNullOrEmpty($DHCPPolicy.VendorClass)) {
                                    $true {"--"}
                                    $false {$DHCPPolicy.VendorClass}
                                    default {"Unknown"}
                                }
                                'User Class' = Switch ([string]::IsNullOrEmpty($DHCPPolicy.UserClass)) {
                                    $true {"--"}
                                    $false {$DHCPPolicy.UserClass}
                                    default {"Unknown"}
                                }
                                'Mac Address' = Switch ([string]::IsNullOrEmpty($DHCPPolicy.MacAddress)) {
                                    $true {"--"}
                                    $false {$DHCPPolicy.MacAddress}
                                    default {"Unknown"}
                                }
                                'Client Id' = Switch ([string]::IsNullOrEmpty($DHCPPolicy.MacAddress)) {
                                    $true {"--"}
                                    $false {$DHCPPolicy.MacAddress}
                                    default {"Unknown"}
                                }
                                'Fqdn' = Switch ([string]::IsNullOrEmpty($DHCPPolicy.Fqdn)) {
                                    $true {"--"}
                                    $false {$DHCPPolicy.Fqdn}
                                    default {"Unknown"}
                                }
                                'Relay Agent' = Switch ([string]::IsNullOrEmpty($DHCPPolicy.RelayAgent)) {
                                    $true {"--"}
                                    $false {$DHCPPolicy.RelayAgent}
                                    default {"Unknown"}
                                }
                                'Circuit Id' = Switch ([string]::IsNullOrEmpty($DHCPPolicy.CircuitId)) {
                                    $true {"--"}
                                    $false {$DHCPPolicy.CircuitId}
                                    default {"Unknown"}
                                }
                                'Remote Id' = Switch ([string]::IsNullOrEmpty($DHCPPolicy.RemoteId)) {
                                    $true {"--"}
                                    $false {$DHCPPolicy.RemoteId}
                                    default {"Unknown"}
                                }
                                'Subscriber Id' = Switch ([string]::IsNullOrEmpty($DHCPPolicy.SubscriberId)) {
                                    $true {"--"}
                                    $false {$DHCPPolicy.SubscriberId}
                                    default {"Unknown"}
                                }
                                'Lease Duration' = Switch ([string]::IsNullOrEmpty($DHCPPolicy.LeaseDuration)) {
                                    $true {"--"}
                                    $false {$DHCPPolicy.LeaseDuration}
                                    default {"Unknown"}
                                }
                                'Description' = Switch ([string]::IsNullOrEmpty($DHCPPolicy.Description)) {
                                    $true {"--"}
                                    $false {$DHCPPolicy.Description}
                                    default {"Unknown"}
                                }
                            }
                            $OutObj = [pscustomobject]$inobj

                            if ($HealthCheck.DHCP.BP) {
                                $OutObj | Where-Object { $_.'Description' -eq "--" } | Set-Style -Style Warning -Property 'Description'
                            }

                            $TableParams = @{
                                Name = "Policy - $($DHCPPolicy.Name)"
                                List = $true
                                ColumnWidths = 50, 50
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $OutObj | Table @TableParams
                        }
                        catch {
                            Write-PscriboMessage -IsWarning "$($_.Exception.Message) (IPv4 Per Scope Policy Item)"
                        }
                    }
                }
            }
        }
        catch {
            Write-PscriboMessage -IsWarning "$($_.Exception.Message) (IPv4 Per Scope Policy Table)"
        }
    }

    end {}

}