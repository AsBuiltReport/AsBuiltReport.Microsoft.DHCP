function Get-AbrADDHCPv4FilterStatus {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Microsoft AD DHCP v4 filter status from Domain Controller
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
            $Domain
    )

    begin {
        Write-PscriboMessage "Discovering Active Directory DHCP Servers filter status information on $($Domain.ToString().ToUpper())."
    }

    process {
        try {
            if ($DHCPinDC) {
                Section -Style Heading3 'Filter Status' {
                    $OutObj = @()
                    try {
                        foreach ($DHCPServer in $DHCPinDC) {
                            if (Test-Connection -ComputerName $DHCPServer.DnsName -Quiet -Count 1) {
                                Write-PScriboMessage "Collecting DHCP Server IPv4 filter status from $($DHCPServer.DnsName.split(".", 2)[0])"
                                $TempCIMSession = New-CIMSession ($DHCPServer).DnsName -Credential $Credential -Authentication $Options.PSDefaultAuthentication -ErrorAction Stop
                                $Setting = Get-DhcpServerv4FilterList -CimSession $TempCIMSession -ComputerName ($DHCPServer).DnsName
                                $inObj = [ordered] @{
                                    'DC Name' = $DHCPServer.DnsName.Split(".", 2)[0]
                                    'Allow' = ConvertTo-EmptyToFiller $Setting.Allow
                                    'Deny' = ConvertTo-EmptyToFiller $Setting.Deny
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
                        Write-PScriboMessage -IsWarning "$($_.Exception.Message) (IPv4 filter status Item)"
                    }

                    $TableParams = @{
                        Name = "Filter Status - $($Domain.ToString().ToUpper())"
                        List = $false
                        ColumnWidths = 40, 30, 30
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $OutObj | Table @TableParams
                }
            }
        }
        catch {
            Write-PScriboMessage -IsWarning "$($_.Exception.Message) (IPv4 Filter Status Table)"
        }
    }

    end {}

}