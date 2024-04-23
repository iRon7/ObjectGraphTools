<#
.SYNOPSIS
    Deserializes a PowerShell expression to an object.

.DESCRIPTION
    The `ConvertFrom-Expression` cmdlet safely converts a PowerShell formatted expression to an object-graph
    existing of a mixture of nested arrays, hashtables and objects that contain a list of strings and values.

.PARAMETER InputObject
    Specifies the PowerShell expressions to convert to objects. Enter a variable that contains the string,
    or type a command or expression that gets the string. You can also pipe a string to ConvertFrom-Expression.

    The **InputObject** parameter is required, but its value can be an empty string.
    The **InputObject** value can't be `$null` or an empty string.

.PARAMETER LanguageMode
    Defines which object types are allowed for the deserialization, see: [About language modes][2]

    * Any type that is not allowed by the given language mode, will be omitted leaving a bare `[ValueType]`,
      `[String]`, `[Array]` or `[HashTable]`.
    * Any variable that is not `$True`, `$False` or `$Null` will be converted to a literal string, e.g. `$Test`.

    > [!Caution]
    >
    > In full language mode, `ConvertTo-Expression` permits all type initializers. Cmdlets, functions,
    > CIM commands, and workflows will *not* be invoked by the `ConvertFrom-Expression` cmdlet.
    >
    > Take reasonable precautions when using the `Invoke-Expression -LanguageMode Full` command in scripts.
    > Verify that the class types in the expression are safe before instantiating them. In general, it is
    > best to design your configuration expressions with restricted or constrained classes, rather than
    > allowing full freeform expressions.

.PARAMETER ArrayAs
    If supplied, the array subexpression `@( )` syntaxes without an type initializer or with an unknown or
    denied type initializer will be converted to the given list type.

.PARAMETER HashTableAs
    If supplied, the array subexpression `@{ }` syntaxes without an type initializer or with an unknown or
    denied type initializer will be converted to the given map (dictionary or object) type.

#>
function ConvertFrom-Expression {
    [CmdletBinding(HelpUri='https://github.com/iRon7/ObjectGraphTools/blob/main/Docs/ConvertFrom-Expression.md')][OutputType([Object])] param(

        [Parameter(Mandatory = $true, ValueFromPipeLine = $True)]
        [Alias('Expression')][String]$InputObject,

        [ValidateScript({ $_ -ne 'NoLanguage' })]
        [System.Management.Automation.PSLanguageMode]$LanguageMode = 'Restricted',

        [ValidateNotNull()]$ArrayAs,

        [ValidateNotNull()]$HashTableAs
    )

    begin {
        function StopError($Exception, $Id = 'IncorrectArgument', $Group = [Management.Automation.ErrorCategory]::SyntaxError, $Object){
            if ($Exception -is [System.Management.Automation.ErrorRecord]) { $Exception = $Exception.Exception }
            elseif ($Exception -isnot [Exception]) { $Exception = [ArgumentException]$Exception }
            $PSCmdlet.ThrowTerminatingError([System.Management.Automation.ErrorRecord]::new($Exception, $Id, $Group, $Object))
        }

        if ($this.LanguageMode -eq 'NoLanguage') { Throw 'The language mode "NoLanguage" is not supported.' }

        function NewNode($Object) { # Should become a New-Node cmdlet
            if ($Null -eq $Object) { return }
            elseif ($Object -is [String] -or $Object -is [Type]) {
                $String = "$Object" # This will use the type accessor for [Type] type.
                if ('Array', 'Object[]' -eq $String) {
                    $Object = @()
                }
                elseif ('ordered', 'OrderedDictionary' -eq $String) {
                    $Object = [System.Collections.Specialized.OrderedDictionary]::new([StringComparer]::OrdinalIgnoreCase)
                }
                elseif ('hashtable' -eq $String) {
                    $Object = [HashTable]::new([StringComparer]::OrdinalIgnoreCase)
                }
                elseif ('psobject', 'PSCustomObject' -eq $String) {
                    $Object = [PSCustomObject]@{}
                }
                else {
                    $Type = $TypeName -as [Type]
                    if (-not $Type) { StopError "Unknown type: [$Object]" }
                    $Object = New-Object -Type $TypeName
                }
            }
            elseif ($Null -ne $Object.GetType().GetMethod('Clear')) {
                $Object.Clear()
            }
            [PSNode]::ParseInput($Object)
        }

        $ArrayNode     = NewNode $ArrayAs
        $HashTableNode = NewNode $HashTableAs

        if (
            $ArrayNode -is [PSMapNode] -and $HashTableNode -is [PSListNode] -or
            -not $ArrayNode -and $HashTableNode -is [PSListNode] -or
            $ArrayNode -is [PSMapNode] -and -not $HashTableNode
        ) {
            $ArrayNode, $HashTableNode = $HashTableNode, $ArrayNode # In case the parameter positions are swapped
        }

        $ArrayType = if ($ArrayNode) {
            if ($ArrayType -is [PSListNode]) { $ArrayNode.ValueType }
            else { StopError 'The -ArrayAs parameter requires a string, type or an object example that supports a list structure' }
        }

        $HashTableType = if ($HashTableNode) {
            if ($HashTableNode -is [PSMapNode]) { $HashTableNode.ValueType }
            else { StopError 'The -HashTableAs parameter requires a string, type or an object example that supports a map structure' }
        }
        if ('System.Management.Automation.PSCustomObject' -eq $HashTableNode.ValueType) { $HashTableType = 'PSCustomObject' -as [type] } # https://github.com/PowerShell/PowerShell/issues/2295
    }

    process {
        [PSDeserialize]::new($InputObject, $LanguageMode, $ArrayType, $HashTableType).Object
    }
}