function Get-AbrADDHCPv6PerScopeExclusion {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Microsoft AD DHCP Servers Scopes Exclusion from DHCP Servers
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
            $Server,
            $Scope
    )

    begin {
        Write-PscriboMessage "Discovering DHCP Servers Scope Exclusion information from $($Server.ToUpper().split(".", 2)[0])."
    }

    process {
        $DHCPScopeExclusion = Get-DhcpServerv6ExclusionRange -CimSession $TempCIMSession -ComputerName $Server -Prefix $Scope | Sort-Object -Property 'StartRange'
        if ($DHCPScopeExclusion) {
            Section -ExcludeFromTOC -Style NOTOCHeading6 "Exclusion" {
                $OutObj = @()
                foreach ($Exclusion in $DHCPScopeExclusion) {
                    try {
                        Write-PscriboMessage "Collecting DHCP Server IPv6 Scope Exclusion value $($Exclusion.IPAddress) from $($Server.split(".", 2)[0])"
                        $inObj = [ordered] @{
                            'Start Range' = $Exclusion.StartRange
                            'End Range' = $Exclusion.EndRange
                        }
                        $OutObj += [pscustomobject]$inobj
                    }
                    catch {
                        Write-PscriboMessage -IsWarning "$($_.Exception.Message) (Scope Exclusion Item)"
                    }
                }

                $TableParams = @{
                    Name = "Scopes Exclusion - $Scope"
                    List = $false
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