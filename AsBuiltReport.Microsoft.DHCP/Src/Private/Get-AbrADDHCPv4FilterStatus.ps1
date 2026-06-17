function Get-AbrADDHCPv4FilterStatus {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Microsoft AD DHCP v4 filter status from Domain Controller
    .DESCRIPTION

    .NOTES
        Version:        0.3.0
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
        Write-PScriboMessage "Discovering Active Directory DHCP Servers filter status information on $($Domain.ToString().ToUpper())."
    }

    process {
        try {
            if ($DHCPinDC) {
                Section -Style Heading3 'Filter Status' {
                    $OutObj = @()
                    try {
                        foreach ($DHCPServer in $DHCPinDC) {
                            if (Test-WSMan -Credential $Credential -Authentication $Options.PSDefaultAuthentication -ComputerName $DHCPServer -ErrorAction SilentlyContinue) {
                                Write-PScriboMessage "Collecting DHCP Server IPv4 filter status from $($DHCPServer.split(".", 2)[0])"
                                $TempCIMSession = New-CimSession $DHCPServer -Credential $Credential -Authentication $Options.PSDefaultAuthentication -ErrorAction Stop
                                $Setting = Get-DhcpServerv4FilterList -CimSession $TempCIMSession -ComputerName $DHCPServer
                                $inObj = [ordered] @{
                                    'DC Name' = $DHCPServer.Split(".", 2)[0]
                                    'Allow' = $Setting.Allow
                                    'Deny' = $Setting.Deny
                                }
                                $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)

                                if ($TempCIMSession) {
                                    Write-PScriboMessage "Clearing CIM Session $($TempCIMSession.Id)"
                                    Remove-CimSession -CimSession $TempCIMSession
                                }
                            }
                        }
                    } catch {
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
        } catch {
            Write-PScriboMessage -IsWarning "$($_.Exception.Message) (IPv4 Filter Status Table)"
        }
    }

    end {}

}