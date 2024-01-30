<#
.SYNOPSIS
    Copy object graph

.DESCRIPTION
    Recursively ("deep") copies a object graph.

.EXAMPLE
    # Deep copy a complete object graph into a new object graph

        $NewObjectGraph = Copy-ObjectGraph $ObjectGraph

.EXAMPLE
    # Copy (convert) an object graph using common PowerShell arrays and PSCustomObjects

        $PSObject = Copy-ObjectGraph $Object -ListAs [Array] -DictionaryAs PSCustomObject

.EXAMPLE
    # Convert a Json string to an object graph with (case insensitive) ordered dictionaries

        $PSObject = $Json | ConvertFrom-Json | Copy-ObjectGraph -DictionaryAs ([Ordered]@{})

.PARAMETER InputObject
    The input object that will be recursively copied.

.PARAMETER ListAs
    If supplied, lists will be converted to the given type (or type of the supplied object example).

.PARAMETER DictionaryAs
    If supplied, dictionaries will be converted to the given type (or type of the supplied object example).
    This parameter also accepts the [`PSCustomObject`][1] types
    By default (if the [-DictionaryAs] parameters is omitted),
    [`Component`][2] objects will be converted to a [`PSCustomObject`][1] type.

.PARAMETER ExcludeLeafs
    If supplied, only the structure (lists, dictionaries, [`PSCustomObject`][1] types and [`Component`][2] types will be copied.
    If omitted, each leaf will be shallow copied

.LINK
    [1]: https://learn.microsoft.com/dotnet/api/system.management.automation.pscustomobject "PSCustomObject Class"
    [2]: https://learn.microsoft.com/dotnet/api/system.componentmodel.component "Component Class"
#>
function Copy-ObjectGraph {
    [OutputType([Object[]])]
    [CmdletBinding(DefaultParameterSetName = 'ListAs')] param(

        [Parameter(Mandatory = $true, ValueFromPipeLine = $true)]
        $InputObject,

        $ListAs,

        $MapAs,

        [Switch]$ExcludeLeafs,

        [Alias('Depth')][int]$MaxDepth = 10
    )
    begin {
        function StopError($Exception, $Id = 'IncorrectArgument', $Group = [Management.Automation.ErrorCategory]::SyntaxError, $Object){
            if ($Exception -is [System.Management.Automation.ErrorRecord]) { $Exception = $Exception.Exception }
            elseif ($Exception -isnot [Exception]) { $Exception = [ArgumentException]$Exception }
            $PSCmdlet.ThrowTerminatingError([System.Management.Automation.ErrorRecord]::new($Exception, $Id, $Group, $Object))
        }

        $ListNode = if ($PSBoundParameters.ContainsKey('ListAs')) {
            if ($ListAs -is [String] -or $ListAs -is [Type]) {
                try { $ListAs = New-Object -Type $ListAs } catch { StopError $_ }
            }
            [PSNode]::ParseInput($ListAs)
        }

        $MapNode = if ($PSBoundParameters.ContainsKey('MapAs')) {
            if ($MapAs -is [String] -or $MapAs -is [Type]) {
                try { $MapAs = New-Object -Type $MapAs } catch { StopError $_ }
            }
            [PSNode]::ParseInput($MapAs)
        }

        if (($ListNode -is [PSMapNode] -and $MapNode -isnot [PSMapNode]) -or ($MapNode -is [PSListNode] -and $ListNode -isnot [PSListNode])) {
            $ListNode, $DictionaryNode = $DictionaryNode, $ListNode
        }

        if ($Null -ne $ListNode -and $ListNode -isnot [PSListNode]) {
            StopError 'The -ListAs parameter requires a string, type or an object example that supports a list structure'
        }
        if ($Null -ne $MapNode -and $MapNode -isnot [PSMapNode]) {
            StopError 'The -MapAs parameter requires a string, type or an object example that supports a map structure'
        }

        function CopyObject(
            [PSNode]$Node,
            [Type]$ListType,
            [Type]$MapType,
            [Switch]$ExcludeLeafs
        ) {
            if ($Node -is [PSLeafNode]) {
                if ($ExcludeLeafs -or $Null -eq $Node.Value) { return $Node.Value }
                else { $Node.Value.PSObject.Copy() }
            }
            elseif ($Node -is [PSListNode]) {
                $Type = if ($Null -ne $ListType) { $ListType } else { $Node.ValueType }
                $Values = $Node.ChildNodes.foreach{ CopyObject $_ -ListType $ListType -MapType $MapType }
                $Values = $Values -as $Type
                ,$Values
            }
            elseif ($Node -is [PSMapNode]) {
                $Type = if ($Null -ne $MapType) { $MapType } else { $Node.ValueType }
                $IsDirectory = $Null -ne $Type.GetInterface('IDictionary')
                if ($IsDirectory) { $Dictionary = New-Object -Type $Type } else { $Dictionary = [Ordered]@{} }
                $Node.ChildNodes.foreach{ $Dictionary[$_.Name] = CopyObject $_ -ListType $ListType -MapType $MapType }
                if ($IsDirectory) { $Dictionary } else { [PSCustomObject]$Dictionary }
            }
        }
    }
    process {
        $PSNode = [PSNode]::ParseInput($InputObject, $MaxDepth)
        CopyObject $PSNode -ListType $ListNode.ValueType -MapType $MapNode.ValueType -ExcludeLeafs:$ExcludeLeafs
    }
}