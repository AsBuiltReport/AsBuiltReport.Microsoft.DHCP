function Invoke-AsBuiltReport.Microsoft.DHCP {
    <#
    .SYNOPSIS
        PowerShell script to document the configuration of Microsoft DHCP in Word/HTML/Text formats
    .DESCRIPTION
        Documents the configuration of Microsoft DHCP in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.2.1
        Author:         Jonathan Colon
        Twitter:        @jcolonfzenpr
        Github:         rebelinux
        Credits:        Iain Brighton (@iainbrighton) - PScribo module

    .LINK
        https://github.com/AsBuiltReport/AsBuiltReport.Microsoft.DHCP
    #>

    # Do not remove or add to these parameters
    param (
        [String[]] $Target,
        [PSCredential] $Credential
    )

    #Requires -Version 5.1
    #Requires -PSEdition Desktop
    #Requires -RunAsAdministrator

    if ($psISE) {
        Write-Error -Message "You cannot run this script inside the PowerShell ISE. Please execute it from the PowerShell Command Window."
        break
    }

    Write-PScriboMessage -Plugin "Module" -IsWarning "Please refer to the AsBuiltReport.Microsoft.DHCP github website for more detailed information about this project."
    Write-PScriboMessage -Plugin "Module" -IsWarning "Do not forget to update your report configuration file after each new release."
    Write-PScriboMessage -Plugin "Module" -IsWarning "Documentation: https://github.com/AsBuiltReport/AsBuiltReport.Microsoft.DHCP"
    Write-PScriboMessage -Plugin "Module" -IsWarning "Issues or bug reporting: https://github.com/AsBuiltReport/AsBuiltReport.Microsoft.DHCP/issues"
    Write-PScriboMessage -Plugin "Module" -IsWarning "This project is community maintained and has no sponsorship from Microsoft, its employees or any of its affiliates."


    try {
        $InstalledVersion = Get-Module -ListAvailable -Name AsBuiltReport.Microsoft.DHCP -ErrorAction SilentlyContinue | Sort-Object -Property Version -Descending | Select-Object -First 1 -ExpandProperty Version

        if ($InstalledVersion) {
            Write-PScriboMessage -IsWarning "AsBuiltReport.Microsoft.DHCP $($InstalledVersion.ToString()) is currently installed."
            $LatestVersion = Find-Module -Name AsBuiltReport.Microsoft.DHCP -Repository PSGallery -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Version
            if ($LatestVersion -gt $InstalledVersion) {
                Write-PScriboMessage -IsWarning "AsBuiltReport.Microsoft.DHCP $($LatestVersion.ToString()) is available."
                Write-PScriboMessage -IsWarning "Run 'Update-Module -Name AsBuiltReport.Microsoft.DHCP -Force' to install the latest version."
            }
        }
    } catch {
        Write-PScriboMessage -IsWarning $_.Exception.Message
    }

    #Validate Required Modules and Features
    $OSType = (Get-ComputerInfo).OsProductType
    if ($OSType -eq 'WorkStation') {
        Get-RequiredFeature -Name 'Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0' -OSType $OSType
        Get-RequiredFeature -Name 'Rsat.DHCP.Tools~~~~0.0.1.0' -OSType $OSType

    }
    if ($OSType -eq 'Server' -or $OSType -eq 'DomainController') {
        Get-RequiredFeature -Name RSAT-AD-PowerShell -OSType $OSType
        Get-RequiredFeature -Name RSAT-DHCP -OSType $OSType
    }


    # Import Report Configuration
    $Report = $ReportConfig.Report
    $InfoLevel = $ReportConfig.InfoLevel
    $Options = $ReportConfig.Options

    # Used to set values to TitleCase where required
    $TextInfo = (Get-Culture).TextInfo

    #region foreach loop
    foreach ($System in $Target) {

        if (Select-String -InputObject $System -Pattern "^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$") {
            throw "Please use the FQDN instead of an IP address to connect to the Domain Controller: $System"
        }

        try {
            $TempCIMSession = New-CimSession -ComputerName $System -Credential $Credential -Authentication $Options.PSDefaultAuthentication -ErrorAction Stop
            $ADSystem = Get-ADForest -ErrorAction Stop -Credential $Credential
        } catch {
            throw "Unable to discover Forest information from $System"
        }



        $script:ForestInfo = $ADSystem.RootDomain.toUpper()
        [array]$RootDomains = $ADSystem.RootDomain
        [array]$ChildDomains = $ADSystem.Domains | Where-Object { $_ -ne $RootDomains }
        [string]$OrderedDomains = $RootDomains + $ChildDomains

        #---------------------------------------------------------------------------------------------#
        #                                 DHCP Section                                                #
        #---------------------------------------------------------------------------------------------#

        if ($Options.ServerDiscovery -eq "Domain") {
            $DHCPinDomain = Get-DhcpServerInDC
            if ($DHCPinDomain) {
                try {
                    Get-AbrADDHCPDomain
                } catch {
                    throw "Unable to get generate DHCP report from $System"
                }
            } else {
                Write-PScriboMessage -IsWarning "Unable to get DHCP discovery from $($System): $($_.Exception.Message) "
            }
        } else {
            $script:DomainDHCPs = $System
            Get-AbrADDHCPStandAlone -Domain $System
        }

        if ($TempCIMSession) {
            Write-PScriboMessage "Clearing CIM Session $($TempCIMSession.Id)"
            Remove-CimSession -CimSession $TempCIMSession
        }
    }
    #endregion foreach loop
}
