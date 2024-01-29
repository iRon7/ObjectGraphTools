Using NameSpace System.Management.Automation.Language

<#
.SYNOPSIS
    Get a node

.DESCRIPTION
    Retrieves a node of an object graph.

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
        $Node.GetDescendentNode($Path)
    }
}

