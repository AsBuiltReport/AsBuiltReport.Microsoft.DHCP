function Get-AbrADDHCPv4PerScopePolicy {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Microsoft AD DHCP Servers Policy from Domain Controller
    .DESCRIPTION

    .NOTES
        Version:        0.2.1
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
        Write-PScriboMessage "Discovering Active Directory DHCP Servers Policy information on $($Domain.ToString().ToUpper())."
    }

    process {
        try {
            $DHCPPolicies = Get-DhcpServerv4Policy -CimSession $TempCIMSession -ComputerName $Server -ScopeId $Scope | Sort-Object -Property 'Name'
            if ($DHCPPolicies) {
                Section -ExcludeFromTOC -Style NOTOCHeading6 "Policies" {
                    $OutObj = @()
                    foreach ($DHCPPolicy in $DHCPPolicies) {
                        try {
                            Write-PScriboMessage "Collecting DHCP Server IPv4 $($DHCPPolicy.Name) policies from $($Server.split(".", 2)[0])"
                            $inObj = [ordered] @{
                                'Name' = $DHCPPolicy.Name
                                'Enabled' = ConvertTo-TextYN $DHCPPolicy.Enabled
                                'Scope Id' = $DHCPPolicy.ScopeId
                                'Processing Order' = $DHCPPolicy.ProcessingOrder
                                'Condition' = $DHCPPolicy.Condition
                                'Vendor Class' = switch ([string]::IsNullOrEmpty($DHCPPolicy.VendorClass)) {
                                    $true { "--" }
                                    $false { $DHCPPolicy.VendorClass }
                                    default { "Unknown" }
                                }
                                'User Class' = switch ([string]::IsNullOrEmpty($DHCPPolicy.UserClass)) {
                                    $true { "--" }
                                    $false { $DHCPPolicy.UserClass }
                                    default { "Unknown" }
                                }
                                'Mac Address' = switch ([string]::IsNullOrEmpty($DHCPPolicy.MacAddress)) {
                                    $true { "--" }
                                    $false { $DHCPPolicy.MacAddress }
                                    default { "Unknown" }
                                }
                                'Client Id' = switch ([string]::IsNullOrEmpty($DHCPPolicy.MacAddress)) {
                                    $true { "--" }
                                    $false { $DHCPPolicy.MacAddress }
                                    default { "Unknown" }
                                }
                                'FQDN' = switch ([string]::IsNullOrEmpty($DHCPPolicy.Fqdn)) {
                                    $true { "--" }
                                    $false { $DHCPPolicy.Fqdn }
                                    default { "Unknown" }
                                }
                                'Relay Agent' = switch ([string]::IsNullOrEmpty($DHCPPolicy.RelayAgent)) {
                                    $true { "--" }
                                    $false { $DHCPPolicy.RelayAgent }
                                    default { "Unknown" }
                                }
                                'Circuit Id' = switch ([string]::IsNullOrEmpty($DHCPPolicy.CircuitId)) {
                                    $true { "--" }
                                    $false { $DHCPPolicy.CircuitId }
                                    default { "Unknown" }
                                }
                                'Remote Id' = switch ([string]::IsNullOrEmpty($DHCPPolicy.RemoteId)) {
                                    $true { "--" }
                                    $false { $DHCPPolicy.RemoteId }
                                    default { "Unknown" }
                                }
                                'Subscriber Id' = switch ([string]::IsNullOrEmpty($DHCPPolicy.SubscriberId)) {
                                    $true { "--" }
                                    $false { $DHCPPolicy.SubscriberId }
                                    default { "Unknown" }
                                }
                                'Lease Duration' = switch ([string]::IsNullOrEmpty($DHCPPolicy.LeaseDuration)) {
                                    $true { "--" }
                                    $false { $DHCPPolicy.LeaseDuration }
                                    default { "Unknown" }
                                }
                                'Description' = switch ([string]::IsNullOrEmpty($DHCPPolicy.Description)) {
                                    $true { "--" }
                                    $false { $DHCPPolicy.Description }
                                    default { "Unknown" }
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
                            if ($HealthCheck.DHCP.BP -and ($OutObj | Where-Object { $_.'Description' -eq "--" } )) {
                                Paragraph "Health Check:" -Bold -Underline
                                BlankLine
                                Paragraph {
                                    Text "Best Practice:" -Bold
                                    Text "It is a general rule of good practice to establish well-defined descriptions. This helps to speed up the fault identification process, as well as enabling better documentation of the environment."
                                }
                            }
                        } catch {
                            Write-PScriboMessage -IsWarning "$($_.Exception.Message) (IPv4 Per Scope Policy Item)"
                        }
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "$($_.Exception.Message) (IPv4 Per Scope Policy Table)"
        }
    }

    end {}

}