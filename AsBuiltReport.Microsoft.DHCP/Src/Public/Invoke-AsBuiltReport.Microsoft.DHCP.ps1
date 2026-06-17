function Invoke-AsBuiltReport.Microsoft.DHCP {
    <#
    .SYNOPSIS
        PowerShell script to document the configuration of Microsoft DHCP in Word/HTML/Text formats
    .DESCRIPTION
        Documents the configuration of Microsoft DHCP in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.3.0
        Author:         Jonathan Colon
        Twitter:        @jcolonfzenpr
        Github:         rebelinux
        Credits:        Iain Brighton (@iainbrighton) - PScribo module

    .LINK
        https://github.com/AsBuiltReport/AsBuiltReport.Microsoft.DHCP
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Scope = 'Function')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingUserNameAndPassWordParams', '', Scope = 'Function')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', '', Scope = 'Function')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Scope = 'Function')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingCmdletAliases', '', Scope = 'Function')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Scope = 'Function')]

    # Do not remove or add to these parameters
    param (
        [String[]] $Target,
        [PSCredential] $Credential
    )

    #Requires -RunAsAdministrator

    if ($psISE) {
        Write-Error -Message 'You cannot run this script inside the PowerShell ISE. Please execute it from the PowerShell Command Window.'
        break
    }

    # Check the version of the dependency modules
    Write-ReportModuleInfo -ModuleName 'Veeam.VBR'

    Write-Host '  To sponsor this project, please visit:' -NoNewline
    Write-Host ' https://ko-fi.com/F1F8DEV80' -ForegroundColor Cyan

    Write-Host '  - Getting dependency information:'
    # Check the version of the dependency modules
    $ModuleArray = @('AsBuiltReport.Core', 'AsBuiltReport.Chart', 'AsBuiltReport.Diagram')

    foreach ($Module in $ModuleArray) {
        try {
            $InstalledVersion = Get-Module -ListAvailable -Name $Module -ErrorAction SilentlyContinue | Sort-Object -Property Version -Descending | Select-Object -First 1 -ExpandProperty Version

            if ($InstalledVersion) {
                Write-Host ('    - {0} module v{1} is currently installed.' -f $Module, $InstalledVersion.ToString())
                $LatestVersion = Find-Module -Name $Module -Repository PSGallery -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Version
                if ($InstalledVersion -lt $LatestVersion) {
                    Write-Host ('    - {0} module v{1} is available.)' -f $Module, $LatestVersion.ToString()) -ForegroundColor Red
                    Write-Host ("    - Run 'Update-Module -Name {0} -Force' to install the latest version." -f $Module) -ForegroundColor Red
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning $_.Exception.Message
        }
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

        if (Select-String -InputObject $System -Pattern '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$') {
            throw "Please use the FQDN instead of an IP address to connect to the Domain Controller: $System"
        }

        try {
            $TempCIMSession = New-CimSession -ComputerName $System -Credential $Credential -Authentication $Options.PSDefaultAuthentication -ErrorAction Stop
            $ADSystem = Get-ADForest -ErrorAction Stop -Credential $Credential
        } catch {
            throw "Unable to discover Forest information from $($System): $($_.Exception.Message)"
        }



        $script:ForestInfo = $ADSystem.RootDomain.toUpper()
        [array]$RootDomains = $ADSystem.RootDomain
        [array]$ChildDomains = $ADSystem.Domains | Where-Object { $_ -ne $RootDomains }
        [string]$OrderedDomains = $RootDomains + $ChildDomains

        #---------------------------------------------------------------------------------------------#
        #                                 DHCP Section                                                #
        #---------------------------------------------------------------------------------------------#

        if ($Options.ServerDiscovery -eq 'Domain') {
            $DHCPinDomain = Get-DhcpServerInDC | Select-Object -Property DNSName -Unique
            if ($DHCPinDomain) {
                try {
                    Write-Host '  - Collecting Forest Wide DHCP information...'
                    Get-AbrADDHCPDomain
                } catch {
                    throw "Unable to get generate DHCP report from $System"
                }
            } else {
                Write-PScriboMessage -IsWarning "Unable to get DHCP discovery from $($System): $($_.Exception.Message)"
            }
        } else {
            $script:DomainDHCPs = $System
            Write-Host "  - Collecting $($System) DHCP information..."
            Get-AbrADDHCPStandAlone -Domain $System
        }

        if ($TempCIMSession) {
            Write-PScriboMessage "Clearing CIM Session $($TempCIMSession.Id)"
            Remove-CimSession -CimSession $TempCIMSession
        }
    }
    #endregion foreach loop
}
