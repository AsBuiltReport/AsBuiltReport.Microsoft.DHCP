function Get-AbrADDHCPv4Statistic {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Microsoft AD DHCP Servers from Domain Controller
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
        Write-PscriboMessage "Discovering Active Directory DHCP Servers information on $($Domain.ToString().ToUpper())."
    }

    process {
        try {
            if ($DHCPinDC) {
                Section -Style Heading3 'Service Statistics' {
                    $OutObj = @()
                    try {
                        foreach ($DHCPServer in $DHCPinDC) {
                            if (Test-Connection -ComputerName $DHCPServer -Quiet -Count 2) {
                                Write-PScriboMessage "Collecting DHCP Server IPv4 Statistics from $($DHCPServer.split(".", 2)[0])"
                                $TempCIMSession = New-CIMSession $DHCPServer -Credential $Credential -Authentication $Options.PSDefaultAuthentication -ErrorAction Stop
                                $Setting = Get-DhcpServerv4Statistics -CimSession $TempCIMSession -ComputerName $DHCPServer
                                $inObj = [ordered] @{
                                    'DC Name' = $DHCPServer.Split(".", 2)[0]
                                    'Total Scopes' = ConvertTo-EmptyToFiller $Setting.TotalScopes
                                    'Total Addresses' = ConvertTo-EmptyToFiller $Setting.TotalAddresses
                                    'Addresses In Use' = ConvertTo-EmptyToFiller $Setting.AddressesInUse
                                    'Addresses Available' = ConvertTo-EmptyToFiller $Setting.AddressesAvailable
                                    'Percentage In Use' = ConvertTo-EmptyToFiller ([math]::Round($Setting.PercentageInUse, 0))
                                    'Percentage Available' = ConvertTo-EmptyToFiller ([math]::Round($Setting.PercentageAvailable, 0))
                                }
                                $OutObj += [pscustomobject]$inobj

                                if ($TempCIMSession) {
                                    Write-PscriboMessage "Clearing CIM Session $($TempCIMSession.Id)"
                                    Remove-CIMSession -CimSession $TempCIMSession
                                }
                            }
                        }
                    }
                    catch {
                        Write-PScriboMessage -IsWarning "$($_.Exception.Message) (IPv4 Service Statistics Item)"
                    }
                    if ($HealthCheck.DHCP.Statistics) {
                        $OutObj | Where-Object { $_.'Percentage In Use' -gt 95} | Set-Style -Style Warning -Property 'Percentage Available','Percentage In Use'
                    }

                    $TableParams = @{
                        Name = "DHCP Server Statistics - $($Domain.ToString().ToUpper())"
                        List = $false
                        ColumnWidths = 20, 13, 13, 13, 14 ,13, 14
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $OutObj | Sort-Object -Property 'DC Name' | Table @TableParams
                }
            }
        }
        catch {
            Write-PScriboMessage -IsWarning "$($_.Exception.Message) (IPv4 Service Statistics Table)"
        }
    }

    end {}

}