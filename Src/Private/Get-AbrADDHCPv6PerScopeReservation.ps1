function Get-AbrADDHCPv6PerScopeReservation {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Microsoft AD DHCP Servers Scopes Reservation from DHCP Servers
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
        Write-PscriboMessage "Discovering DHCP Servers Scope Reservation information from $($Server.ToUpper().split(".", 2)[0])."
    }

    process {
        $DHCPScopeReservation = Get-DhcpServerv6Reservation  -CimSession $TempCIMSession -ComputerName $Server -Prefix $Scope | Sort-Object -Property 'IPAddress'
        if ($DHCPScopeReservation) {
            Section -ExcludeFromTOC -Style NOTOCHeading6 "Reservations" {
                $OutObj = @()
                foreach ($Reservation in $DHCPScopeReservation) {
                    try {
                        Write-PscriboMessage "Collecting DHCP Server IPv6 Scope Reservation value $($Reservation.IPAddress) from $($Server.split(".", 2)[0])"
                        $inObj = [ordered] @{
                            'IP Address' = $Reservation.IPAddress
                            'Client Id' = $Reservation.ClientId
                            'Name' = $Reservation.Name
                            'Type' = $Reservation.Type
                        }
                        $OutObj += [pscustomobject]$inobj
                    }
                    catch {
                        Write-PscriboMessage -IsWarning "$($_.Exception.Message) (Scope IPV6 Reservation Item)"
                    }
                }

                $TableParams = @{
                    Name = "Scopes Reservation - $Scope"
                    List = $false
                    ColumnWidths = 25, 25, 35, 15
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