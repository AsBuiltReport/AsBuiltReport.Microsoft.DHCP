function Get-AbrADDHCPv4PerScopeProperty {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Microsoft AD DHCP Servers Scopes Properties from DHCP Servers
    .DESCRIPTION

    .NOTES
        Version:        0.1.1
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
        Write-PscriboMessage "Discovering DHCP Servers Scope Properties information from $($Server.ToUpper().split(".", 2)[0])."
    }

    process {
        $DHCPScopeExclusion = Get-DhcpServerv4Scope -CimSession $TempCIMSession -ComputerName $Server -ScopeId $Scope | Sort-Object -Property 'ScopeId'
        if ($DHCPScopeExclusion) {
            Section -ExcludeFromTOC -Style NOTOCHeading6 "Properties" {
                $OutObj = @()
                foreach ($Exclusion in $DHCPScopeExclusion) {
                    try {
                        Write-PscriboMessage "Collecting DHCP Server IPv4 Scope Properties value $($Exclusion.IPAddress) from $($Server.split(".", 2)[0])"
                        $inObj = [ordered] @{
                            'Name' = $Exclusion.Name
                            'Type' = $Exclusion.Type
                            'Lease Duration' = $Exclusion.LeaseDuration
                            'Start Range' = $Exclusion.StartRange
                            'End Range' = $Exclusion.EndRange
                            'Subnet Mask' = $Exclusion.SubnetMask
                            'Delay(ms)' = $Exclusion.Delay
                            'State' = $Exclusion.State
                            'Max Bootp Clients' = $Exclusion.MaxBootpClients
                            'Activate Policies' = ConvertTo-EmptyToFiller $Exclusion.ActivatePolicies
                            'Nap Enable' = ConvertTo-EmptyToFiller $Exclusion.NapEnable
                            'Nap Profile' = ConvertTo-EmptyToFiller $Exclusion.NapProfile
                            'Description' = ConvertTo-EmptyToFiller $Exclusion.Description
                        }
                        $OutObj += [pscustomobject]$inobj
                    }
                    catch {
                        Write-PscriboMessage -IsWarning "$($_.Exception.Message) (Scope Properties Item)"
                    }
                }


                if ($HealthCheck.DHCP.BP) {
                    $OutObj | Where-Object { $Null -eq $_.'Description' } | Set-Style -Style Warning -Property 'Description'
                    $OutObj | Where-Object { $_.'State' -eq "Inactive" } | Set-Style -Style Warning -Property 'State'
                }


                $TableParams = @{
                    Name = "Scopes Properties - $Scope"
                    List = $true
                    ColumnWidths = 50, 50
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $OutObj | Table @TableParams
            }
        }
    }

    end {}

}