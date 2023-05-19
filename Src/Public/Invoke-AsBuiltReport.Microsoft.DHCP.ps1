function Invoke-AsBuiltReport.Microsoft.DHCP {
    <#
    .SYNOPSIS
        PowerShell script to document the configuration of Microsoft DHCP in Word/HTML/Text formats
    .DESCRIPTION
        Documents the configuration of Microsoft DHCP in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.1.0
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

    Write-PScriboMessage -IsWarning "Please refer to the AsBuiltReport.Microsoft.DHCP github website for more detailed information about this project."
    Write-PScriboMessage -IsWarning "Do not forget to update your report configuration file after each new release."
    Write-PScriboMessage -IsWarning "Documentation: https://github.com/AsBuiltReport/AsBuiltReport.Microsoft.DHCP"
    Write-PScriboMessage -IsWarning "Issues or bug reporting: https://github.com/AsBuiltReport/AsBuiltReport.Microsoft.DHCP/issues"

    Try {
        $InstalledVersion = Get-Module -ListAvailable -Name AsBuiltReport.Microsoft.DHCP -ErrorAction SilentlyContinue | Sort-Object -Property Version -Descending | Select-Object -First 1 -ExpandProperty Version

        if ($InstalledVersion) {
            Write-PScriboMessage -IsWarning "AsBuiltReport.Microsoft.DHCP $($InstalledVersion.ToString()) is currently installed."
            $LatestVersion = Find-Module -Name AsBuiltReport.Microsoft.DHCP -Repository PSGallery -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Version
            if ($LatestVersion -gt $InstalledVersion) {
                Write-PScriboMessage -IsWarning "AsBuiltReport.Microsoft.DHCP $($LatestVersion.ToString()) is available."
                Write-PScriboMessage -IsWarning "Run 'Update-Module -Name AsBuiltReport.Microsoft.DHCP -Force' to install the latest version."
            }
        }
    } Catch {
            Write-PscriboMessage -IsWarning $_.Exception.Message
    }

    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())

    if (-Not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {

        throw "The requested operation requires elevation: Run PowerShell console as administrator"
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
        Try {
            $TempCIMSession = New-CIMSession -ComputerName $System -Credential $Credential -Authentication $Options.PSDefaultAuthentication -ErrorAction Stop
            $ADSystem = Get-ADForest -ErrorAction Stop -Credential $Credential
        } Catch {
            throw "Unable to discover Forest information from $System"
        }

        Try {
            $DHCPinDomain = Get-DhcpServerInDC
        } Catch {
            throw "Unable to get DHCP discovery from $System"
        }

        $script:ForestInfo =  $ADSystem.RootDomain.toUpper()
        [array]$RootDomains = $ADSystem.RootDomain
        [array]$ChildDomains = $ADSystem.Domains | Where-Object {$_ -ne $RootDomains}
        [string]$OrderedDomains = $RootDomains + $ChildDomains

        #---------------------------------------------------------------------------------------------#
        #                                 DHCP Section                                                #
        #---------------------------------------------------------------------------------------------#

        Section -Style Heading1 "DHCP Configuration" {
            if ($InfoLevel.DHCP -ge 1 -and $DHCPinDomain ) {
                foreach ($Domain in ($OrderedDomains.split(" "))) {
                    if ($Domain -notin $Options.Exclude.Domains) {
                        try {
                            $DomainInfo = Get-ADDomain $Domain -ErrorAction Stop
                            if ($DomainInfo) {
                                Get-AbrDHCPReport -Domain $DomainInfo
                            }
                        } catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
                            Write-PScriboMessage -IsWarning "Unable to retreive $($Domain) information. Removing Domain from report"
                        }
                    }
                }
            }
        }#endregion DHCP Section

        if ($TempCIMSession) {
            Write-PscriboMessage "Clearing CIM Session $($TempCIMSession.Id)"
            Remove-CIMSession -CimSession $TempCIMSession
        }
	}
	#endregion foreach loop
}
