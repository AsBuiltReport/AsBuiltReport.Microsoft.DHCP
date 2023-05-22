function Get-AbrADDHCPv4Scope {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Microsoft Active Directory DHCP Servers Scopes.
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
            $Domain,
            [string]
            $Server
    )

    begin {
        Write-PscriboMessage "Discovering Active Directory DHCP Servers information on $($Domain.ToString().ToUpper())."
    }

    process {
        try {
            $DHCPScopes = Get-DhcpServerv4Scope -CimSession $TempCIMSession -ComputerName $Server
            if ($DHCPScopes) {
                Section -Style Heading4 "Scopes" {
                    Paragraph "The following sections summarizes the configuration of the ipv4 scope within $($Server.ToUpper().split(".", 2)[0])."
                    BlankLine
                    $OutObj = @()
                    foreach ($Scope in $DHCPScopes) {
                        Write-PscriboMessage "Collecting DHCP Server IPv4 $($Scope.ScopeId) Scope from $($Server.split(".", 2)[0])"
                        try {
                            $SubnetMask = Convert-IpAddressToMaskLength $Scope.SubnetMask.IPAddressToString
                            $inObj = [ordered] @{
                                'Scope Id' = "$($Scope.ScopeId)/$($SubnetMask)"
                                'Scope Name' = $Scope.Name
                                'Scope Range' = "$($Scope.StartRange) - $($Scope.EndRange)"
                                'Lease Duration' = Switch ($Scope.LeaseDuration) {
                                    "10675199.02:48:05.4775807" {"Unlimited"}
                                    default {$Scope.LeaseDuration}
                                }
                                'State' = $Scope.State
                            }
                            $OutObj += [pscustomobject]$inobj
                        }
                        catch {
                            Write-PscriboMessage -IsWarning "$($_.Exception.Message) (IPv4 Scope Item)"
                        }
                    }

                    if ($HealthCheck.DHCP.BP) {
                        $OutObj | Where-Object { $_.'State' -ne 'Active'} | Set-Style -Style Warning -Property 'State'
                    }

                    $TableParams = @{
                        Name = "Scopes - $($Server.split(".", 2).ToUpper()[0])"
                        List = $false
                        ColumnWidths = 20, 20, 35, 15, 10
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $OutObj | Sort-Object -Property 'Scope Id' | Table @TableParams

                    if ($HealthCheck.DHCP.BP -and ($OutObj | Where-Object { $_.'State' -ne 'Active'} )) {
                        Paragraph "Health Check:" -Italic -Bold -Underline
                        Paragraph "Corrective Action: Ensure inactive scope are removed from DHCP server." -Italic -Bold
                    }
                }
                try {
                    $DHCPScopes = Get-DhcpServerv4ScopeStatistics -CimSession $TempCIMSession -ComputerName $Server
                    if ($DHCPScopes) {
                        Section -Style Heading4 "Scope Statistics" {
                            $OutObj = @()
                            foreach ($Scope in $DHCPScopes) {
                                try {
                                    Write-PscriboMessage "Collecting DHCP Server IPv4 $($Scope.ScopeId) scope statistics from $($Server.split(".", 2)[0])"
                                    $inObj = [ordered] @{
                                        'Scope Id' = $Scope.ScopeId
                                        'Free IP' = $Scope.Free
                                        'In Use IP' = $Scope.InUse
                                        'Percentage In Use' = [math]::Round($Scope.PercentageInUse, 0)
                                        'Reserved IP' = $Scope.Reserved
                                    }
                                    $OutObj += [pscustomobject]$inobj
                                }
                                catch {
                                    Write-PscriboMessage -IsWarning "$($_.Exception.Message) (IPv4 Scope Statistics Item)"
                                }
                            }

                            if ($HealthCheck.DHCP.Statistics) {
                                $OutObj | Where-Object { $_.'Percentage In Use' -gt '95'} | Set-Style -Style Warning -Property 'Percentage In Use'
                            }

                            $TableParams = @{
                                Name = "IPv4 Scope Statistics - $($Server.split(".", 2).ToUpper()[0])"
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
                    Write-PscriboMessage -IsWarning "$($_.Exception.Message) (IPv4 Scope Statistics Table)"
                }
                try {
                    $DHCPScopes = Get-DhcpServerv4Failover -CimSession $TempCIMSession -ComputerName $Server
                    if ($DHCPScopes) {
                        Section -Style Heading4 "Scope Failover" {
                            Write-PScriboMessage "Discovered '$(($DHCPScopes | Measure-Object).Count)' failover setting in $($Server)."
                            foreach ($Scope in $DHCPScopes) {
                                if ($Scope.ScopeId) {
                                    try {
                                        Section -ExcludeFromTOC -Style NOTOCHeading5 $Scope.ScopeId.IPAddressToString {
                                            $OutObj = @()
                                            Write-PscriboMessage "Collecting DHCP Server IPv4 $($Scope.ScopeId.IPAddressToString) scope failover setting from $($Server.split(".", 2)[0])"
                                            $inObj = [ordered] @{
                                                'DHCP Server' = $Server
                                                'Partner DHCP Server' = $Scope.PartnerServer
                                                'Mode' = $Scope.Mode
                                                'LoadBalance Percent' = ConvertTo-EmptyToFiller ([math]::Round($Scope.LoadBalancePercent, 0))
                                                'Server Role' = ConvertTo-EmptyToFiller $Scope.ServerRole
                                                'Reserve Percent' = ConvertTo-EmptyToFiller ([math]::Round($Scope.ReservePercent, 0))
                                                'Max Client Lead Time' = ConvertTo-EmptyToFiller $Scope.MaxClientLeadTime
                                                'State Switch Interval' = ConvertTo-EmptyToFiller $Scope.StateSwitchInterval
                                                'Scope Ids' = $Scope.ScopeId.IPAddressToString
                                                'State' = $Scope.State
                                                'Auto State Transition' = ConvertTo-TextYN $Scope.AutoStateTransition
                                                'Authetication Enable' = ConvertTo-TextYN $Scope.EnableAuth
                                            }
                                            $OutObj = [pscustomobject]$inobj

                                            if ($HealthCheck.DHCP.BP) {
                                                $OutObj | Where-Object { $_.'Authetication Enable' -eq 'No'} | Set-Style -Style Warning -Property 'Authetication Enable'
                                            }

                                            $TableParams = @{
                                                Name = "IPv4 Scope Failover Cofiguration - $($Server.split(".", 2).ToUpper()[0])"
                                                List = $true
                                                ColumnWidths = 40, 60
                                            }
                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }

                                            $OutObj | Table @TableParams

                                            if ($HealthCheck.DHCP.BP -and ($OutObj | Where-Object { $_.'Authetication Enable' -eq 'No'})) {
                                                Paragraph "Health Check:" -Italic -Bold -Underline
                                                Paragraph "Corrective Action: Ensure Dhcp servers require authentication (a shared secret) in order to secure communications between failover partners." -Italic -Bold
                                            }
                                        }
                                    }
                                    catch {
                                        Write-PscriboMessage -IsWarning "$($_.Exception.Message) (IPv4 Scope Failover Item)"
                                    }
                                }
                            }
                        }
                    }
                }
                catch {
                    Write-PscriboMessage -IsWarning "$($_.Exception.Message) (IPv4 Scope Failover Table)"
                }
                try {
                    $DHCPScopes = Get-DhcpServerv4Binding -CimSession $TempCIMSession -ComputerName $Server
                    if ($DHCPScopes) {
                        Section -Style Heading4 "NIC Binding" {
                            $OutObj = @()
                            foreach ($Scope in $DHCPScopes) {
                                try {
                                    Write-PscriboMessage "Collecting DHCP Server IPv4 $($Scope.InterfaceAlias) binding from $($Server.split(".", 2)[0])"
                                    $SubnetMask = Convert-IpAddressToMaskLength $Scope.SubnetMask
                                    $inObj = [ordered] @{
                                        'Interface Alias' = $Scope.InterfaceAlias
                                        'IP Address' = $Scope.IPAddress
                                        'Subnet Mask' = $Scope.SubnetMask
                                        'State' = Switch ($Scope.BindingState) {
                                            ""  {"-"; break}
                                            $Null  {"-"; break}
                                            "True"  {"Enabled"}
                                            "False"  {"Disabled"}
                                            default {$Scope.BindingState}
                                        }
                                    }
                                    $OutObj += [pscustomobject]$inobj
                                }
                                catch {
                                    Write-PscriboMessage -IsWarning "$($_.Exception.Message) (IPv4 NIC Biding Item)"
                                }
                            }
                            if ($HealthCheck.DHCP.BP) {
                                $OutObj | Where-Object { $_.'State' -ne 'Enabled'} | Set-Style -Style Warning -Property 'State'
                            }
                            $TableParams = @{
                                Name = "NIC Biding - $($Server.split(".", 2).ToUpper()[0])"
                                List = $false
                                ColumnWidths = 25, 25, 25, 25
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $OutObj | Table @TableParams
                        }
                    }
                }
                catch {
                    Write-PscriboMessage -IsWarning "$($_.Exception.Message) (IPv4 Network Interface binding Table)"
                }
                try {
                    $DHCPClass = Get-DhcpServerv4Class -CimSession $TempCIMSession -ComputerName $Server | Sort-Object -Property 'Name'
                    if ($DHCPClass) {
                        Section -Style Heading4 "Client Classes" {
                            $OutObj = @()
                            foreach ($Class in $DHCPClass) {
                                try {
                                    Write-PscriboMessage "Collecting DHCP Server IPv4 $($Class.Name) class from $($Server.split(".", 2)[0])"
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
                                    Write-PscriboMessage -IsWarning "$($_.Exception.Message) (IPv4 Client Classes Item)"
                                }
                            }

                            if ($HealthCheck.DHCP.BP) {
                                $OutObj | Where-Object { $Null -eq $_.'Description'} | Set-Style -Style Warning -Property 'Description'
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
                        }
                    }
                }
                catch {
                    Write-PscriboMessage -IsWarning "$($_.Exception.Message) (IPv4 Client Classes Table)"
                }
                try {
                    $DHCPOptionDefinition = Get-DhcpServerv4OptionDefinition -CimSession $TempCIMSession -ComputerName $Server | Sort-Object -Property 'OptionId'
                    if ($DHCPOptionDefinition) {
                        Section -Style Heading4 "Option Definitions" {
                            $OutObj = @()
                            foreach ($Definition in $DHCPOptionDefinition) {
                                try {
                                    Write-PscriboMessage "Collecting DHCP Server IPv4 $($Definition.Name) option definitions from $($Server.split(".", 2)[0])"
                                    $inObj = [ordered] @{
                                        'Name' = $Definition.Name
                                        'Option Id' = $Definition.OptionId
                                        'Type' = $Definition.Type
                                        'Vendor Class' = $Definition.VendorClass
                                        'Multi Valued' = ConvertTo-TextYN $Definition.MultiValued
                                    }
                                    $OutObj += [pscustomobject]$inobj
                                }
                                catch {
                                    Write-PscriboMessage -IsWarning "$($_.Exception.Message) (IPv4 Option Definitions Item)"
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
                    Write-PscriboMessage -IsWarning "$($_.Exception.Message) (IPv4 Client Classes Table)"
                }
            }
        }
        catch {
            Write-PscriboMessage -IsWarning "$($_.Exception.Message) (IPv4 Scope Summary)"
        }
    }
    end {}
}