<#
.SYNOPSIS
    Serializes an object to a PowerShell expression.

.DESCRIPTION
    The ConvertTo-Expression cmdlet converts (serializes) an object to a
    PowerShell expression. The object can be stored in a variable,  file or
    any other common storage for later use or to be ported to another
    system.

    An expression can be restored to an object using the native
    Invoke-Expression cmdlet:

        $Object = Invoke-Expression ($Object | ConvertTo-Expression)

    Or Converting it to a [ScriptBlock] and invoking it with cmdlets
    along with Invoke-Command or using the call operator (&):

        $Object = &([ScriptBlock]::Create($Object | ConvertTo-Expression))

    An expression that is stored in a PowerShell (.ps1) file might also
    be directly invoked by the PowerShell dot-sourcing technique,  e.g.:

        $Object | ConvertTo-Expression | Out-File .\Expression.ps1
        $Object = . .\Expression.ps1

    Warning: Invoking partly trusted input with Invoke-Expression or
    [ScriptBlock]::Create() methods could be abused by malicious code
    injections.

.INPUTS
    Any. Each objects provided through the pipeline will converted to an
    expression. To concatenate all piped objects in a single expression,
    use the unary comma operator,  e.g.: ,$Object | ConvertTo-Expression

.OUTPUTS
    String[]. ConvertTo-Expression returns a PowerShell [String] expression
    for each input object.

.PARAMETER InputObject
    Specifies the objects to convert to a PowerShell expression. Enter a
    variable that contains the objects,  or type a command or expression
    that gets the objects. You can also pipe one or more objects to
    ConvertTo-Expression.

.PARAMETER MaxDepth
    Specifies how many levels of contained objects are included in the
    PowerShell representation. The default value is 9.

.PARAMETER IndentSize
    Specifies how many IndentChars to write for each level in the hierarchy.

.PARAMETER IndentChar
    Specifies which character to use for indenting.

.LINK
    https://www.powershellgallery.com/packages/ConvertFrom-Expression
#>

function ConvertTo-Expression {
    [Diagnostics.CodeAnalysis.SuppressMessage('PSUseApprovedVerbs', '')]
    [CmdletBinding()][OutputType([Object[]])] param(

        [Parameter(Mandatory = $true, ValueFromPipeLine = $True)]
        $InputObject,

        [Int]$Expand = [Int]::MaxValue,

        [int]$IndentSize = 4,

        [string]$IndentChar = ' ',

        [Alias('Depth')][int]$MaxDepth = [PSNode]::DefaultMaxDepth
    )
    begin {
        $Script:Indent = $IndentChar * $IndentSize
        function ConvertToExpression(
            [String]$Indent,
            [String]$Prefix,
            [PSNode]$Node,
            [String]$Suffix,
            [Int]$Expand = $Expand
        ) {
            if ($Node -is [PSListNode]) {
                $Indent1 = if ($Indent -or $Prefix) { $Indent + $Script:Indent }
                $ChildNodes = $Node.get_ChildNodes()
                if ($ChildNodes) {
                    if ($Indent1) { "$Indent$Prefix@(" }
                    for ($i = 0; $i -lt $ChildNodes.Count; $i++) {
                        $Suffix = if ($i -lt $ChildNodes.Count - 1) { ',' }
                        ConvertToExpression -Indent $Indent1 -Node $ChildNodes[$i] -Suffix $Suffix
                    }
                    if ($Indent1) { "$Indent)$Suffix" }
                }
                else { "$Indent$Prefix@()$Suffix" }
            }
            elseif ($Node -is [PSMapNode]) {
                $Indent1 = $Indent + $Script:Indent
                $ChildNodes = $Node.get_ChildNodes()
                if ($ChildNodes) {
                    "$Indent$Prefix@{"
                    foreach ($ChildNode in $ChildNodes) {
                        $Name =
                            if ($ChildNode.Name -is [String] -and $ChildNode.Name -Match [XdnPath]::Verbatim) { $ChildNode.Name }
                            elseif ($ChildNode.Type.IsPrimitive) { $ChildNode.Name }
                            else { "'$($ChildNode.Name)'" }
                        ConvertToExpression -Indent $Indent1 -Prefix "$Name = " -Node $ChildNode
                    }
                    "$Indent}$Suffix"
                }
                else { "$Indent$Prefix@{}$Suffix" }
            }
            else { # if ($Node -is [PSLeafNode])
                $Value = $Node.Value
                $Expression =
                    if ($Null -eq $Value) { '$Null' }
                    elseif ($Value -is [Boolean]) { if ($Value) { '$True' } else { '$False' } }
                    elseif ('ADSI' -as [type] -and $Value -is [ADSI]) { "'$($Value.ADsPath)'" }
                    elseif ($Node.Type -in 'Char', 'MailAddress', 'Regex', 'Semver', 'Type', 'Version', 'Uri') { "'$($Value)'" }
                    elseif ($Type.IsPrimitive) { "$Value" }
                    elseif ($Value -is [String]) { "'$Value'" } # Check for here string
                    #elseif ($Value -is [SecureString]) { "'$($Value | ConvertFrom-SecureString)'" -Convert 'ConvertTo-SecureString' }
                    #elseif ($Value -is [PSCredential]) { $Value.Username, $Value.Password -Convert 'New-Object PSCredential' }
                    elseif ($Value -is [DateTime]) { "'$($Value.ToString('o'))'" }
                    elseif ($Value -is [Enum]) { "'$Value'" }
                    elseif ($Value -is [ScriptBlock]) { if ($Value -match "\#.*?$") { "{ $Value$NewLine }" } else { "{ $Value }" } }
                    elseif ($Value -is [RuntimeTypeHandle]) { "$($Value.Value)" }
                    else   { $Value }
                "$Indent$Prefix$Expression$Suffix"
            }
        }
    }

    process {
        $Node = [PSNode]::ParseInput($InputObject, $MaxDepth)
        ConvertToExpression -Node $Node

    }
}
