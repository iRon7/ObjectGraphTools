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

        [Parameter(Mandatory = $true, ValueFromPipeLine = $true, ValueFromPipelineByPropertyName = $true)]
        $Path
    )
    begin {
        function StopError($Exception, $Id = 'IncorrectArgument', $Group = [Management.Automation.ErrorCategory]::SyntaxError, $Object){
            if ($Exception -is [System.Management.Automation.ErrorRecord]) { $Exception = $Exception.Exception }
            elseif ($Exception -isnot [Exception]) { $Exception = [ArgumentException]$Exception }
            $PSCmdlet.ThrowTerminatingError([System.Management.Automation.ErrorRecord]::new($Exception, $Id, $Group, $Object))
        }

        function WarnSelector ([PSCollectionNode]$Node, $Name) {
            if ($Node -is [PSListNode]) {
                $SelectionName  = "'$Name'"
                $CollectionType = 'list'
            }
            else {
                $SelectionName  = "[$Name]"
                $CollectionType = 'list'
            }
            Write-Warning "Expected $SelectionName to be a $CollectionType selector for: <Object>$($Node.PathName)"
        }

        function GetAstSelectors ([Ast]$Ast) {
            if ($Ast -isnot [Ast]) {
                $Ast = [Parser]::ParseInput("`$_$Ast", [ref]$Null, [ref]$Null)
                $Ast = $Ast.EndBlock.Statements.PipeLineElements.Expression
            }
            if ($Ast -is [IndexExpressionAst]) {
                GetAstSelectors $Ast.Target
                $Ast
            }
            elseif ($Ast -is [MemberExpressionAst]) {
                GetAstSelectors $Ast.Expression
                $Ast
            }
            elseif ($Ast.Extent.Text -ne '$_') {
                Throw "Parse error: $($Ast.Extent.Text)"
            }
        }
        $RootNode = [PSNode]::ParseInput($ObjectGraph)
    }
    process {
        if ($Path -is [String] -and ($Path.StartsWith('.') -or $Path.StartsWith('['))) {
            $Ast  = [Parser]::ParseInput("`$_$Path", [ref]$Null, [ref]$Null)
            $Ast = $Ast.EndBlock.Statements.PipeLineElements.Expression
            $Selectors = GetAstSelectors $Ast
        }
        elseif ($Path -is [PSNode]) { $Selectors = $Path.Path }
        else { $Selectors = $Path }
        $Node = $RootNode
        foreach ($Selector in $Selectors) {
            if ($Node -is [PSLeafNode]) {
                StopError "Can not select child node in <object>$($Node.PathName) as it is a leaf node."
            }
            elseif ($Selector -is [IndexExpressionAst]) {
                $Name = $Selector.Index.Value
                if ($Node -isnot [PSListNode]) { WarnSelector $Node $Name }
            }
            elseif ($Selector -is [MemberExpressionAst]) {
                $Name = $Selector.Member.Value
                if ($Node -isnot [PSMapNode]) { WarnSelector $Node $Name }
            }
            else {
                $Name = if ($Selector.PSObject.Properties['Name']) { $Selector.Name } else { $Selector }
                if ($Selector -is [PSNode]) {
                    if ($Selector.PSNodeOrigin -eq 'List' -and  $Node -isnot [PSListNode]) { WarnSelector $Node $Name }
                    if ($Selector.PSNodeOrigin -eq 'Map'  -and  $Node -isnot [PSMapNode])  { WarnSelector $Node $Name }
                }
                elseif ($Name -is [Int]) {
                    if ($Node.Type.IsGenericType -and $Node.Type.GetGenericArguments()[0].Name -eq 'String') { WarnSelector $Node $Name }
                }
                else {
                    if ($Node -isnot [PSMapNode]) {WarnSelector $Node $Name }
                }
            }
            if ($Null -ne $Name) { $Node = $Node.GetChildNode($Name) } # Not sure yet whether $Null should selected the current node or the root node...
        }
        $Node
    }
}

