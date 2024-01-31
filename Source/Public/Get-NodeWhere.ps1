<#
.SYNOPSIS
    Get node where

.DESCRIPTION
    Selects nodes from a object or `[PSNode]` collection based on their property values.

    This cmdlet is based on the native `Microsoft.PowerShell.Core\Where-Object` cmdlet.
    It differs in the fact that it a returns a collection of [`PSNode`][1] instances where the condition is applied on the embedded object value contained by a supplied input nodes.

.PARAMETER CContains
    Indicates that this cmdlet gets nodes from a collection if the property value of the node is an exact match for the specified value. This operation is case-sensitive.

    For example: `...| Get-NodeWhere Name -CContains Joe`

    `CContains` refers to a collection of values and is true if the collection contains a node value property that is an exact match for the specified value.
    If the node is a single object, PowerShell converts it to a collection of one node.

.PARAMETER CEQ
    Indicates that this cmdlet gets nodes if the value property is the same as the specified value. This operation is case-sensitive.

.PARAMETER CGE
    Indicates that this cmdlet gets nodes if the value property is greater than or equal to the specified value. This operation is case-sensitive.

.PARAMETER CGT
    Indicates that this cmdlet gets nodes if the value property is greater than the specified value. This operation is case-sensitive.

.PARAMETER CIn
    Indicates that this cmdlet gets nodes if the value property includes the specified value. This operation is case-sensitive.

    For example: `... | Get-NodeWhere -Value Joe -CIn Name`

    [CIn] resembles [CContains], except that the property and value positions are reversed. For example, the following statements are both true.

        "abc", "def" -CContains "abc"

        "abc" -CIn "abc", "def"

.PARAMETER CLE
    Indicates that this cmdlet gets nodes if the value property is less-than or equal to the specified value. This operation is case-sensitive.

.PARAMETER CLike
    Indicates that this cmdlet gets nodes if the value property matches a value that includes wildcard characters (*). This operation is case-sensitive.

    For example: `... | Get-NodeWhere Name -CLike Joe*`

.PARAMETER CLT
    Indicates that this cmdlet gets nodes if the value property is less-than the specified value. This operation is case-sensitive.

.PARAMETER CMatch
    Indicates that this cmdlet gets nodes if the value property matches the specified regular expression. This operation is case-sensitive. When the input is a single node, the matched value is saved in the `$Matches` automatic variable.

    For example: `... | Get-NodeWhere Name -CMatch 'Joe\d*'`

.PARAMETER CNE
    Indicates that this cmdlet gets nodes if the value property is different than the specified value. This operation is case-sensitive.

.PARAMETER CNotContains
    Indicates that this cmdlet gets nodes if the value property of the object isn't an exact match for the specified value. This operation is case-sensitive.

    For example: `... | Get-NodeWhere Name -CNotContains Joe`

    `NotContains` and `CNotContains` refer to a collection of nodes and are true when the collection doesn't contain any node items that are an exact match for the specified value. If the input is a single node, PowerShell converts it to a collection of one node.

.PARAMETER CNotIn
    Indicates that this cmdlet gets nodes if the value property isn't an exact match for the specified value. This operation is case-sensitive.

    For example: `... | Get-NodeWhere -Value "Joe" -CNotIn -Property Name`

    `NotIn` and `CNotIn` operators resemble `NotContains` and `CNotContains`, except that the property and value positions are reversed. For example, the following statements are true.

        "abc", "def" -CNotContains "Abc"

        "abc" -CNotIn "Abc", "def"

.PARAMETER CNotLike
    Indicates that this cmdlet gets nodes if the value property doesn't match a value that includes wildcard characters. This operation is case-sensitive.

    For example: `... | Get-NodeWhere Name -CNotLike "*Joe"`

.PARAMETER CNotMatch
    Indicates that this cmdlet gets nodes if the value property doesn't match the specified regular expression. This operation is case-sensitive. When the input is a single node, the matched value is saved in the `$Matches` automatic variable.

    For example: `... | Get-NodeWhere Name -CNotMatch "Joe/d*"`

.PARAMETER Contains
    Indicates that this cmdlet gets nodes if any item in the value property of the object is an exact match for the specified value.

    For example: `...| Get-NodeWhere Name -Contains Joe`

    If the input is a single node, PowerShell converts it to a collection of one node.

.PARAMETER EQ
    Indicates that this cmdlet gets nodes if the value property is the same as the specified value.

.PARAMETER FilterScript
    Specifies the script block that's used to filter the nodes by its contained value. Enclose the script block in braces (`{}`).

.PARAMETER GE
    Indicates that this cmdlet gets nodes if the value property is greater than or equal to the specified value.

.PARAMETER GT
    Indicates that this cmdlet gets nodes if the value property is greater than the specified value.

.PARAMETER In
    Indicates that this cmdlet gets nodes if the value property matches any of the specified values. For example:

        ... | Get-NodeWhere -Property Name -in -Value "Joe", "John", "iRon"

    If the input is a single node, PowerShell converts it to a collection of one node.

    If the value property of a node is an array, PowerShell uses reference equality to determine a match. `Get-NodeWhere` returns the node only if the value of the **Property** parameter and any value of the embedded **value property** are the same instance of a node.

.PARAMETER InputObject
    Specifies the nodes to filter. Any object that is not yet a node, will be automatically parsed to a `[PSNode]` type. You can also pipe the nodes to `Get-NodeWhere`.

    When you use the [-InputObject] parameter with `Get-NodeWhere`t, instead of piping command results to `Get-NodeWhere`, the cmdlet treats the InputObject as a single node. This is true even if the value is a collection that's the result of a command, such as [-InputObject] (Get-Process).

    Because InputObject can't return individual properties from an array or collection of nodes, it is recommended that, if you use `Get-NodeWhere` to filter a collection of nodes for those nodes that have specific values in defined properties, you use `Get-NodeWhere` in the pipeline,

.PARAMETER Is
    Indicates that this cmdlet gets nodes if the value property is an instance of the specified .NET type. Enclose the type name in square brackets.

    For example: `... | Get-NodeWhere StartTime -Is [DateTime]`

.PARAMETER IsNot
    Indicates that this cmdlet gets nodes if the value property isn't an instance of the specified .NET type.

    For example: `... | Get-NodeWhere StartTime -IsNot [DateTime]`

.PARAMETER LE
    Indicates that this cmdlet gets nodes if the value property is less than or equal to the specified value.

.PARAMETER Like
    Indicates that this cmdlet gets node if the value property matches a value that includes wildcard characters (*).

    For example: `... | Get-NodeWhere Name -Like "*Joe"`

.PARAMETER LT
    Indicates that this cmdlet gets nodes if the value property is less than the specified value.

.PARAMETER Match
    Indicates that this cmdlet gets nodes if the value property matches the specified regular expression. When the input is a single node, the matched value is saved in the `$Matches` automatic variable.

    For example: `... | Get-NodeWhere Name -Match "Joe/d*"`

.PARAMETER NE
    Indicates that this cmdlet gets nodes if the value property is different than the specified value.

.PARAMETER Not
    Indicates that this cmdlet gets nodes if the value property doesn't exist or has a value of `null` or `$false`.

    For example: `... | Get-NodeWhere -Not "Index"`

.PARAMETER NotContains
    Indicates that this cmdlet gets nodes if none of the items in the value property is an exact match for the specified value.

    For example: `... | Get-NodeWhere Name -NotContains Joe`

    `NotContains` refers to a collection of values and is true if the collection doesn't contain any items that are an exact match for the specified value. If the input is a single node, PowerShell converts it to a collection of one node.

.PARAMETER NotIn
    Indicates that this cmdlet gets nodes if the value property isn't an exact match for any of the specified values.

    For example: `... | Get-NodeWhere -Value Joe -NotIn -Property Name`

    If the value of Value is a single node, PowerShell converts it to a collection of one node.

    If the value property of an node is an array, PowerShell uses reference equality to determine a match. `Get-NodeWhere` returns the node only if the value of the **Property** parameter and any value of the embedded **value property** are the same instance of a node.

.PARAMETER NotLike
    Indicates that this cmdlet gets nodes if the value property doesn't match a value that includes wildcard characters (*).

    For example: `... | Get-NodeWhere Name -NotLike "Joe*"`

.PARAMETER NotMatch
    Indicates that this cmdlet gets nodes when the value property value doesn't match the specified regular expression. When the input is a single node, the matched value is saved in the `$Matches` automatic variable.

    For example: `... | Get-NodeWhere Name -NotMatch "Joe/d*"`

.PARAMETER Property
    Specifies the name of an node value property. The parameter name, `-Property`, is optional.

.PARAMETER Value
    Specifies a property value of the node's embedded object value. The parameter name, `-Value`, is optional. This parameter accepts wildcard characters when used with the following comparison parameters:

    * [-CLike]
    * [-CNotLike]
    * [-Like]
    * [-NotLike]

.LINK
    [1]: https://github.com/iRon7/ObjectGraphTools/blob/main/Docs/ObjectParser.md "PowerShell Object Parser"
#>
function Get-NodeWhere {
    [CmdletBinding(DefaultParameterSetName='EqualSet', HelpUri='https://go.microsoft.com/fwlink/?LinkID=113423', RemotingCapability='None')]
    param(
        [Parameter(ValueFromPipeline=$true)]
        [PSObject]
        ${InputNode},

        [Parameter(ParameterSetName='ScriptBlockSet', Mandatory=$true, Position=0)]
        [scriptblock]
        ${FilterScript},

        [Parameter(ParameterSetName='CaseSensitiveContainsSet', Mandatory=$true, Position=0)]
        [Parameter(ParameterSetName='CaseSensitiveEqualSet', Mandatory=$true, Position=0)]
        [Parameter(ParameterSetName='NotEqualSet', Mandatory=$true, Position=0)]
        [Parameter(ParameterSetName='CaseSensitiveNotEqualSet', Mandatory=$true, Position=0)]
        [Parameter(ParameterSetName='GreaterThanSet', Mandatory=$true, Position=0)]
        [Parameter(ParameterSetName='CaseSensitiveGreaterThanSet', Mandatory=$true, Position=0)]
        [Parameter(ParameterSetName='LessThanSet', Mandatory=$true, Position=0)]
        [Parameter(ParameterSetName='CaseSensitiveLessThanSet', Mandatory=$true, Position=0)]
        [Parameter(ParameterSetName='GreaterOrEqualSet', Mandatory=$true, Position=0)]
        [Parameter(ParameterSetName='CaseSensitiveGreaterOrEqualSet', Mandatory=$true, Position=0)]
        [Parameter(ParameterSetName='LessOrEqualSet', Mandatory=$true, Position=0)]
        [Parameter(ParameterSetName='CaseSensitiveLessOrEqualSet', Mandatory=$true, Position=0)]
        [Parameter(ParameterSetName='LikeSet', Mandatory=$true, Position=0)]
        [Parameter(ParameterSetName='CaseSensitiveLikeSet', Mandatory=$true, Position=0)]
        [Parameter(ParameterSetName='NotLikeSet', Mandatory=$true, Position=0)]
        [Parameter(ParameterSetName='CaseSensitiveNotLikeSet', Mandatory=$true, Position=0)]
        [Parameter(ParameterSetName='MatchSet', Mandatory=$true, Position=0)]
        [Parameter(ParameterSetName='CaseSensitiveMatchSet', Mandatory=$true, Position=0)]
        [Parameter(ParameterSetName='NotMatchSet', Mandatory=$true, Position=0)]
        [Parameter(ParameterSetName='CaseSensitiveNotMatchSet', Mandatory=$true, Position=0)]
        [Parameter(ParameterSetName='ContainsSet', Mandatory=$true, Position=0)]
        [Parameter(ParameterSetName='EqualSet', Mandatory=$true, Position=0)]
        [Parameter(ParameterSetName='NotContainsSet', Mandatory=$true, Position=0)]
        [Parameter(ParameterSetName='CaseSensitiveNotContainsSet', Mandatory=$true, Position=0)]
        [Parameter(ParameterSetName='InSet', Mandatory=$true, Position=0)]
        [Parameter(ParameterSetName='CaseSensitiveInSet', Mandatory=$true, Position=0)]
        [Parameter(ParameterSetName='NotInSet', Mandatory=$true, Position=0)]
        [Parameter(ParameterSetName='CaseSensitiveNotInSet', Mandatory=$true, Position=0)]
        [Parameter(ParameterSetName='IsSet', Mandatory=$true, Position=0)]
        [Parameter(ParameterSetName='IsNotSet', Mandatory=$true, Position=0)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Property},

        [Parameter(ParameterSetName='CaseSensitiveGreaterOrEqualSet', Position=1)]
        [Parameter(ParameterSetName='CaseSensitiveEqualSet', Position=1)]
        [Parameter(ParameterSetName='NotEqualSet', Position=1)]
        [Parameter(ParameterSetName='CaseSensitiveNotEqualSet', Position=1)]
        [Parameter(ParameterSetName='GreaterThanSet', Position=1)]
        [Parameter(ParameterSetName='CaseSensitiveGreaterThanSet', Position=1)]
        [Parameter(ParameterSetName='LessThanSet', Position=1)]
        [Parameter(ParameterSetName='CaseSensitiveLessThanSet', Position=1)]
        [Parameter(ParameterSetName='GreaterOrEqualSet', Position=1)]
        [Parameter(ParameterSetName='EqualSet', Position=1)]
        [Parameter(ParameterSetName='LessOrEqualSet', Position=1)]
        [Parameter(ParameterSetName='CaseSensitiveLessOrEqualSet', Position=1)]
        [Parameter(ParameterSetName='LikeSet', Position=1)]
        [Parameter(ParameterSetName='CaseSensitiveLikeSet', Position=1)]
        [Parameter(ParameterSetName='NotLikeSet', Position=1)]
        [Parameter(ParameterSetName='CaseSensitiveNotLikeSet', Position=1)]
        [Parameter(ParameterSetName='MatchSet', Position=1)]
        [Parameter(ParameterSetName='CaseSensitiveMatchSet', Position=1)]
        [Parameter(ParameterSetName='NotMatchSet', Position=1)]
        [Parameter(ParameterSetName='CaseSensitiveNotMatchSet', Position=1)]
        [Parameter(ParameterSetName='ContainsSet', Position=1)]
        [Parameter(ParameterSetName='CaseSensitiveContainsSet', Position=1)]
        [Parameter(ParameterSetName='NotContainsSet', Position=1)]
        [Parameter(ParameterSetName='CaseSensitiveNotContainsSet', Position=1)]
        [Parameter(ParameterSetName='InSet', Position=1)]
        [Parameter(ParameterSetName='CaseSensitiveInSet', Position=1)]
        [Parameter(ParameterSetName='NotInSet', Position=1)]
        [Parameter(ParameterSetName='CaseSensitiveNotInSet', Position=1)]
        [Parameter(ParameterSetName='IsSet', Position=1)]
        [Parameter(ParameterSetName='IsNotSet', Position=1)]
        [System.Object]
        ${Value},

        [Parameter(ParameterSetName='EqualSet')]
        [Alias('IEQ')]
        [switch]
        ${EQ},

        [Parameter(ParameterSetName='CaseSensitiveEqualSet', Mandatory=$true)]
        [switch]
        ${CEQ},

        [Parameter(ParameterSetName='NotEqualSet', Mandatory=$true)]
        [Alias('INE')]
        [switch]
        ${NE},

        [Parameter(ParameterSetName='CaseSensitiveNotEqualSet', Mandatory=$true)]
        [switch]
        ${CNE},

        [Parameter(ParameterSetName='GreaterThanSet', Mandatory=$true)]
        [Alias('IGT')]
        [switch]
        ${GT},

        [Parameter(ParameterSetName='CaseSensitiveGreaterThanSet', Mandatory=$true)]
        [switch]
        ${CGT},

        [Parameter(ParameterSetName='LessThanSet', Mandatory=$true)]
        [Alias('ILT')]
        [switch]
        ${LT},

        [Parameter(ParameterSetName='CaseSensitiveLessThanSet', Mandatory=$true)]
        [switch]
        ${CLT},

        [Parameter(ParameterSetName='GreaterOrEqualSet', Mandatory=$true)]
        [Alias('IGE')]
        [switch]
        ${GE},

        [Parameter(ParameterSetName='CaseSensitiveGreaterOrEqualSet', Mandatory=$true)]
        [switch]
        ${CGE},

        [Parameter(ParameterSetName='LessOrEqualSet', Mandatory=$true)]
        [Alias('ILE')]
        [switch]
        ${LE},

        [Parameter(ParameterSetName='CaseSensitiveLessOrEqualSet', Mandatory=$true)]
        [switch]
        ${CLE},

        [Parameter(ParameterSetName='LikeSet', Mandatory=$true)]
        [Alias('ILike')]
        [switch]
        ${Like},

        [Parameter(ParameterSetName='CaseSensitiveLikeSet', Mandatory=$true)]
        [switch]
        ${CLike},

        [Parameter(ParameterSetName='NotLikeSet', Mandatory=$true)]
        [Alias('INotLike')]
        [switch]
        ${NotLike},

        [Parameter(ParameterSetName='CaseSensitiveNotLikeSet', Mandatory=$true)]
        [switch]
        ${CNotLike},

        [Parameter(ParameterSetName='MatchSet', Mandatory=$true)]
        [Alias('IMatch')]
        [switch]
        ${Match},

        [Parameter(ParameterSetName='CaseSensitiveMatchSet', Mandatory=$true)]
        [switch]
        ${CMatch},

        [Parameter(ParameterSetName='NotMatchSet', Mandatory=$true)]
        [Alias('INotMatch')]
        [switch]
        ${NotMatch},

        [Parameter(ParameterSetName='CaseSensitiveNotMatchSet', Mandatory=$true)]
        [switch]
        ${CNotMatch},

        [Parameter(ParameterSetName='ContainsSet', Mandatory=$true)]
        [Alias('IContains')]
        [switch]
        ${Contains},

        [Parameter(ParameterSetName='CaseSensitiveContainsSet', Mandatory=$true)]
        [switch]
        ${CContains},

        [Parameter(ParameterSetName='NotContainsSet', Mandatory=$true)]
        [Alias('INotContains')]
        [switch]
        ${NotContains},

        [Parameter(ParameterSetName='CaseSensitiveNotContainsSet', Mandatory=$true)]
        [switch]
        ${CNotContains},

        [Parameter(ParameterSetName='InSet', Mandatory=$true)]
        [Alias('IIn')]
        [switch]
        ${In},

        [Parameter(ParameterSetName='CaseSensitiveInSet', Mandatory=$true)]
        [switch]
        ${CIn},

        [Parameter(ParameterSetName='NotInSet', Mandatory=$true)]
        [Alias('INotIn')]
        [switch]
        ${NotIn},

        [Parameter(ParameterSetName='CaseSensitiveNotInSet', Mandatory=$true)]
        [switch]
        ${CNotIn},

        [Parameter(ParameterSetName='IsSet', Mandatory=$true)]
        [switch]
        ${Is},

        [Parameter(ParameterSetName='IsNotSet', Mandatory=$true)]
        [switch]
        ${IsNot})

    begin
    {
        try {
            $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Microsoft.PowerShell.Core\Where-Object', [System.Management.Automation.CommandTypes]::Cmdlet)
            $scriptCmd = {& $wrappedCmd @PSBoundParameters }
            $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
            $steppablePipeline.Begin($true)
        } catch {
            throw
        }
    }

    process
    {
        $Node = [PSNode]::ParseInput($_)
        try {
            if ($steppablePipeline.Process($Node.Value).get_Count()) { $Node }
        } catch {
            $PSCmdlet.ThrowTerminatingError($Node.Value)
        }
    }

    end
    {
        try {
            $steppablePipeline.End()
        } catch {
            throw
        }
    }
}

Set-Alias -Name 'Where-NodeValue' -Value 'Get-NodeWhere' -Scope Global
