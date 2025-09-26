function ConvertTo-TextYN {
    <#
    .SYNOPSIS
        Used by As Built Report to convert true or false automatically to Yes or No.
    .DESCRIPTION

    .NOTES
        Version:        0.4.0
        Author:         LEE DAILEY

    .EXAMPLE

    .LINK

    #>
    [CmdletBinding()]
    [OutputType([String])]
    Param (
        [Parameter (
            Position = 0,
            Mandatory)]
        [AllowEmptyString()]
        [string] $TEXT
    )

    switch ($TEXT) {
        "" { "--"; break }
        " " { "--"; break }
        $Null { "--"; break }
        "True" { "Yes"; break }
        "False" { "No"; break }
        default { $TEXT }
    }
} # end

function ConvertTo-FileSizeString {
    <#
    .SYNOPSIS
    Used by As Built Report to convert bytes automatically to GB or TB based on size.
    .DESCRIPTION
    .NOTES
        Version:        0.1.0
        Author:         Jonathan Colon
    .EXAMPLE
    .LINK
    #>
    [CmdletBinding()]
    [OutputType([String])]
    Param
    (
        [Parameter (
            Position = 0,
            Mandatory)]
        [int64]
        $Size
    )

    $Unit = Switch ($Size) {
        { $Size -gt 1PB } { 'PB' ; Break }
        { $Size -gt 1TB } { 'TB' ; Break }
        { $Size -gt 1GB } { 'GB' ; Break }
        { $Size -gt 1Mb } { 'MB' ; Break }
        Default { 'KB' }
    }
    return "$([math]::Round(($Size / $("1" + $Unit)), 0)) $Unit"
} # end

function ConvertTo-EmptyToFiller {
    <#
        .SYNOPSIS
        Used by As Built Report to convert empty culumns to "--".
        .DESCRIPTION

        .NOTES
            Version:        0.4.0
            Author:         Jonathan Colon

        .EXAMPLE

        .LINK

        #>
    [CmdletBinding()]
    [OutputType([String])]
    Param
    (
        [Parameter (
            Position = 0,
            Mandatory)]
        [AllowEmptyString()]
        [string]
        $TEXT
    )

    switch ($TEXT) {
        "" { "--"; break }
        $Null { "--"; break }
        "True" { "Yes"; break }
        "False" { "No"; break }
        default { $TEXT }
    }
} # end

function Convert-IpAddressToMaskLength {
    <#
    .SYNOPSIS
    Used by As Built Report to convert subnet mask to dotted notation.
    .DESCRIPTION

    .NOTES
        Version:        0.4.0
        Author:         Ronald Rink

    .EXAMPLE

    .LINK

    #>
    [CmdletBinding()]
    [OutputType([String])]
    Param
    (
        [Parameter (
            Position = 0,
            Mandatory)]
        [string]
        $SubnetMask
    )

    [IPAddress] $MASK = $SubnetMask
    $octets = $MASK.IPAddressToString.Split('.')
    $result = $Null
    foreach ($octet in $octets) {
        while (0 -ne $octet) {
            $octet = ($octet -shl 1) -band [byte]::MaxValue
            $result++;
        }
    }
    return $result;
}

function ConvertTo-HashToYN {
    <#
    .SYNOPSIS
        Used by As Built Report to convert array content true or false automatically to Yes or No.
    .DESCRIPTION

    .NOTES
        Version:        0.1.0
        Author:         Jonathan Colon

    .EXAMPLE

    .LINK

    #>
    [CmdletBinding()]
    [OutputType([Hashtable])]
    Param (
        [Parameter (Position = 0, Mandatory)]
        [AllowEmptyString()]
        [Hashtable] $TEXT
    )

    $result = [ordered] @{}
    foreach ($i in $inObj.GetEnumerator()) {
        try {
            $result.add($i.Key, (ConvertTo-TextYN $i.Value))
        } catch {
            $result.add($i.Key, ($i.Value))
        }
    }
    if ($result) {
        return $result
    } else { return $TEXT }
} # end