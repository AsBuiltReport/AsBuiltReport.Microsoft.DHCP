function Get-AbrADDHCPv6Scope {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Microsoft Active Directory DHCP Servers Scopes.
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
        Write-PscriboMessage "Discovering Active Directory DHCP Servers information on $($Domain.ToString().ToUpper())."
    }

    process {
        $DHCPScopes = Get-DhcpServerv6Scope -CimSession $TempCIMSession -ComputerName $Server
        if ($DHCPScopes) {
            Section -Style Heading4 "Scopes" {
                Paragraph "The following sections detail the configuration of the IPv6 scope within $($Server.ToUpper().split(".", 2)[0])."
                BlankLine
                $OutObj = @()
                foreach ($Scope in $DHCPScopes) {
                    try {
                        Write-PscriboMessage "Collecting DHCP Server IPv6 $($Scope.ScopeId) Scope from $($Server.split(".", 2)[0])"
                        $inObj = [ordered] @{
                            'Scope Id' = "$($Scope.Prefix)/$($Scope.PrefixLength)"
                            'Scope Name' = $Scope.Name
                            'Lease Duration' = Switch ($Scope.PreferredLifetime) {
                                "10675199.02:48:05.4775807" {"Unlimited"}
                                default {$Scope.PreferredLifetime}
                            }
                            'State' = $Scope.State
                        }
                        $OutObj += [pscustomobject]$inobj
                    }
                    catch {
                        Write-PscriboMessage -IsWarning "$($_.Exception.Message) (IPv6 Scope Item)"
                    }
                }

                $TableParams = @{
                    Name = "Scopes - $($Server.split(".", 2).ToUpper()[0])"
                    List = $false
                    ColumnWidths = 30, 30, 20, 20
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $OutObj | Sort-Object -Property 'Scope Id' | Table @TableParams
            }
            try {
                $DHCPScopes = Get-DhcpServerv6ScopeStatistics -CimSession $TempCIMSession -ComputerName $Server
                if ($DHCPScopes) {
                    Section -Style Heading4 "Scope Statistics" {
                        $OutObj = @()
                        foreach ($Scope in $DHCPScopes) {
                            try {
                                Write-PscriboMessage "Collecting DHCP Server IPv6 $($Scope.ScopeId) scope statistics from $($Server.split(".", 2)[0])"
                                $inObj = [ordered] @{
                                    'Scope Id' = $Scope.Prefix
                                    'Free IP' = $Scope.AddressesFree
                                    'In Use IP' = $Scope.AddressesInUse
                                    'Percentage In Use' = [math]::Round($Scope.PercentageInUse, 0)
                                    'Reserved IP' = $Scope.ReservedAddress
                                }
                                $OutObj += [pscustomobject]$inobj
                            }
                            catch {
                                Write-PscriboMessage -IsWarning "$($_.Exception.Message) (IPv6 Scope Statistics Item)"
                            }
                        }
                        if ($HealthCheck.DHCP.Statistics) {
                            $OutObj | Where-Object { $_.'Percentage In Use' -gt '95'} | Set-Style -Style Warning -Property 'Percentage In Use'
                        }

                        $TableParams = @{
                            Name = "Scope Statistics -  $($Server.split(".", 2).ToUpper()[0])"
                            List = $false
                            ColumnWidths = 20, 20, 20, 20, 20
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $OutObj | Sort-Object -Property 'Scope Id' | Table @TableParams
                    }
                }
            }
            catch {
                Write-PscriboMessage -IsWarning "$($_.Exception.Message) (IPv6 Scope Statistics Table)"
            }
            try {
                $DHCPScopes = Get-DhcpServerv6Binding -CimSession $TempCIMSession -ComputerName $Server
                if ($DHCPScopes) {
                    Section -Style Heading4 "NIC Binding" {
                        $OutObj = @()
                        foreach ($Scope in $DHCPScopes) {
                            try {
                            Write-PscriboMessage "Collecting DHCP Server IPv6 $($Scope.InterfaceAlias) binding from $($Server.split(".", 2)[0])"
                                $inObj = [ordered] @{
                                    'Interface Alias' = $Scope.InterfaceAlias
                                    'IP Address' = $Scope.IPAddress
                                    'State' = Switch ($Scope.BindingState) {
                                        ""  {"--"; break}
                                        $Null  {"--"; break}
                                        "True"  {"Enabled"}
                                        "False"  {"Disabled"}
                                        default {$Scope.BindingState}
                                    }
                                }
                                $OutObj += [pscustomobject]$inobj
                            }
                            catch {
                                Write-PscriboMessage -IsWarning "$($_.Exception.Message) (IPv6 NIC binding item)"
                            }
                        }

                        $TableParams = @{
                            Name = "NIC Binding - $($Server.split(".", 2).ToUpper()[0])"
                            List = $false
                            ColumnWidths = 30, 40, 30
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $OutObj | Table @TableParams
                    }
                }
            }
            catch {
                Write-PscriboMessage -IsWarning "$($_.Exception.Message) (IPv6 Network Interface binding table)"
            }
            try {
                $DHCPClass = Get-DhcpServerv6Class -CimSession $TempCIMSession -ComputerName $Server | Sort-Object -Property 'Name'
                if ($DHCPClass) {
                    Section -Style Heading4 "Client Classes" {
                        $OutObj = @()
                        foreach ($Class in $DHCPClass) {
                            try {
                                Write-PscriboMessage "Collecting DHCP Server IPv6 $($Class.Name) class from $($Server.split(".", 2)[0])"
                                $inObj = [ordered] @{
                                    'Name' = $Class.Name
                                    'Type' = $Class.Type
                                    'Data' = $Class.Data
                                    'Ascii Data' = $Class.AsciiData
                                    'Description' = $Class.Description
                                }
                                $OutObj += [pscustomobject]$inobj
                            }
                            catch {
                                Write-PscriboMessage -IsWarning "$($_.Exception.Message) (IPv6 Client Classes Item)"
                            }
                        }

                        if ($HealthCheck.DHCP.BP) {
                            $OutObj | Where-Object { $_.'Description' -eq '--'} | Set-Style -Style Warning -Property 'Description'
                        }

                        $TableParams = @{
                            Name = "Client Classes - $($Server.split(".", 2).ToUpper()[0])"
                            List = $false
                            ColumnWidths = 24, 12, 24, 20, 20
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $OutObj | Table @TableParams
                        if ($HealthCheck.DHCP.BP -and ($OutObj | Where-Object { $_.'Description' -eq "--" } )) {
                            Paragraph "Health Check:" -Italic -Bold -Underline
                            BlankLine
                            Paragraph "Best Practice: It is a general rule of good practice to establish well-defined descriptions. This helps to speed up the fault identification process, as well as enabling better documentation of the environment." -Italic -Bold
                        }
                    }
                }
            }
            catch {
                Write-PscriboMessage -IsWarning "$($_.Exception.Message) (IPv6 Client Classes Table)"
            }
            try {
                $DHCPOptionDefinition = Get-DhcpServerv6OptionDefinition -CimSession $TempCIMSession -ComputerName $Server | Sort-Object -Property 'OptionId'
                if ($DHCPOptionDefinition) {
                    Section -Style Heading4 "Option Definitions" {
                        $OutObj = @()
                        foreach ($Definition in $DHCPOptionDefinition) {
                            try {
                                Write-PscriboMessage "Collecting DHCP Server IPv6 $($Definition.Name) option definitions from $($Server.split(".", 2)[0])"
                                $inObj = [ordered] @{
                                    'Name' = $Definition.Name
                                    'Option Id' = $Definition.OptionId
                                    'Type' = $Definition.Type
                                    'Vendor Class' = ConvertTo-EmptyToFiller $Definition.VendorClass
                                    'Multi Valued' = ConvertTo-TextYN $Definition.MultiValued
                                }
                                $OutObj += [pscustomobject]$inobj
                            }
                            catch {
                                Write-PscriboMessage -IsWarning "$($_.Exception.Message) (IPv6 Option Definitions Item)"
                            }
                        }

                        $TableParams = @{
                            Name = "Option Definitions - $($Server.split(".", 2).ToUpper()[0])"
                            List = $false
                            ColumnWidths = 30, 12, 22, 22, 14
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $OutObj | Table @TableParams
                    }
                }
            }
            catch {
                Write-PscriboMessage -IsWarning "$($_.Exception.Message) (IPv6 Client Classes Table)"
            }
        }
    }

    end {}

}