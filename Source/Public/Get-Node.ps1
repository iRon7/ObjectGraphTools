Using NameSpace System.Management.Automation.Language

<#
.SYNOPSIS
    Get a node

.DESCRIPTION
    The Get-Node cmdlet gets the node at the specified property location of the supplied object graph.

.EXAMPLE
        # Parse a object graph to a node instance

    The following example parses a hash table to `[PSNode]` instance:

        Get-Node @{ 'My' = 1, 2, 3; 'Object' = 'Graph' }

        PathName Name Depth Value
        -------- ---- ----- -----
                          0 {My, Object}

.EXAMPLE
        # select a sub node in an object graph

    The following example parses a hash table to `[PSNode]` instance and selects the second (`0` indexed)
    item in the `My` map node

        '.My[1]' | Get-Node @{ 'My' = 1, 2, 3; 'Object' = 'Graph' }

        PathName Name Depth Value
        -------- ---- ----- -----
        .My[1]      1     2     2


.PARAMETER ObjectGraph
    The concerned object graph or node.

.PARAMETER Path
    Specifies the path to a specific node in the object graph.
    The path might be either:

    * As [String] a "dot-property" selection as defined by the `PathName` property a specific node.
    * A array of strings (dictionary keys or Property names) and/or Integers (list indices).
    * A object (`PSNode[]`) list where each `Name` property defines the path

.PARAMETER MaxDepth
    Specifies the maximum depth that an object graph might be recursively iterated before it throws an error.
    The failsafe will prevent infinitive loops for circular references as e.g. in:

        $Test = @{Guid = New-Guid}
        $Test.Parent = $Test

    The default `MaxDepth` is defined by `[PSNode]::DefaultMaxDepth = 10`.

    > [!Note]
    > The `MaxDepth` is bound to the root node of the object graph. Meaning that a descendent node
    > at depth of 3 can only recursively iterated (`10 - 3 =`) `7` times.
#>

function Get-Node {
    [OutputType([PSNode])]
    [CmdletBinding()] param(
        [Parameter(Mandatory = $true)]
        $ObjectGraph,

        [Parameter(ValueFromPipeLine = $true, ValueFromPipelineByPropertyName = $true)]
        $Path,

        [Int]
        $MaxDepth
    )
    begin {
        function StopError($Exception, $Id = 'IncorrectArgument', $Group = [Management.Automation.ErrorCategory]::SyntaxError, $Object){
            if ($Exception -is [System.Management.Automation.ErrorRecord]) { $Exception = $Exception.Exception }
            elseif ($Exception -isnot [Exception]) { $Exception = [ArgumentException]$Exception }
            $PSCmdlet.ThrowTerminatingError([System.Management.Automation.ErrorRecord]::new($Exception, $Id, $Group, $Object))
        }

        if ($PSBoundParameters.ContainsKey('MaxDepth')) {
            $Node = [PSNode]::ParseInput($ObjectGraph, $MaxDepth)
        }
        else {
            $Node = [PSNode]::ParseInput($ObjectGraph)
        }
    }
    process {
        if ($ObjectGraph -is [PSNode]) { $Node = $ObjectGraph }
        else { $Node = [PSNode]::ParseInput($ObjectGraph) }
        # try { $Node.GetDescendentNode($Path) } catch { StopError $_ }
        if ($Null -eq $Path) { $Node } else { $Node.GetDescendentNode($Path) }
    }
}

