<#
.SYNOPSIS
    Tests the properties of an object-graph.

.DESCRIPTION
    Tests an object-graph against a schema object by verifying that the properties of the object-graph
    meet the constrains defined in the schema object.
#>

Enum NodeType { Leaf; List; Map }

# JsonSchema Properties
# Schema properties: [Newtonsoft.Json.Schema.JsonSchema]::New() | Get-Member
# https://www.newtonsoft.com/json/help/html/Properties_T_Newtonsoft_Json_Schema_JsonSchema.htm
Enum PSSchemaName {
    Title
    Node
    Type
    Items
}
function New-Schema {
    [CmdletBinding(HelpUri='https://github.com/iRon7/ObjectGraphTools/blob/main/Docs/Test-ObjectGraph.md')][OutputType([String])] param(

        [Parameter(Mandatory = $true, ValueFromPipeLine = $True)]
        $InputObject,

        [Parameter(Mandatory = $true)]
        $SchemaObject,

        [Alias('Depth')][int]$MaxDepth = [PSNode]::DefaultMaxDepth
    )



    begin {


        $NodeTypeCache = [System.Collections.Generic.Dictionary[String,NodeType]]::new()

        $NodeNames = {
            PSLeafNode       = 'Leaf'
            PSListNode       = 'List'
            PSDictionaryNode = 'Map'
            PSObjectNode     = 'Map'
        }
        function TestObject([PSNode]$ObjectNode, [PSNode]$SchemaNode) {
            $Verbose = $VerbosePreference -in 'Stop', 'Continue', 'Inquire'
            if ($Verbose) { Write-Verbose $ObjectNode.Path }
            $ObjectNodeType = $NodeNames["$ObjectNode"]
            $SchemaNodeType = $Null
            foreach ($PSSchemaName in [PSSchemaName].GetEnumValues()) {
                if (-not $DefinitionNode.GetChildNode("$PSSchemaName")) { continue }
                $DefinitionNode = $SchemaNode.GetChildNode("$PSSchemaName")
                $Test = Switch ($PSSchemaName) {
                    Title {
                        Write-Verbose "    $($DefinitionNode.Value)"
                    }
                    Node { # Should be tested before the type
                        $SchemaNodeType = [NodeType]$DefinitionNode.Value
                        if ($ObjectNodeType -ne $SchemaNodeType) {
                            "Expected $($ObjectNode.Path) to be a SchemaNodeType node, but got $($ObjectNode.Value) which is a $ObjectNodeType node."
                        }
                    }
                    Type {
                        $Type = $DefinitionNode.Value -as [Type]
                        if (-not $Type) {
                            Throw "Schema error at $($SchemaNode.Path).Type: Unknown type [$($DefinitionNode.Value)] in schema definition"
                        }
                        if ($SchemaNodeType) {
                                if (-Not $NodeTypeCache.ContainsKey($Type)) {
                                $PSInstance = [PSInstance]::Create($Type)
                                $NodeTypeCache[$Type] = $NodeNames["$PSInstance"]
                            }
                            if ($SchemaNodeType -ne $NodeTypeCache[$Type]) {
                                Throw "Schema error at $($SchemaNode.Path).Type: $Type is not a $SchemaNodeType node"
                            }
                        }
                        if ($ObjectNode.Value -isnot $Type) {
                            "Expected $($ObjectNode.Path) to be a [$($DefinitionNode.Value)] type, but got $($ObjectNode.Value) of type [$($Object.GetType())]."
                        }
                    }
                    Items {
                        if ($ObjectNode -is [PSMapNode]) {
                            if ($SchemaNode -is [PSMapNode]) {
                                foreach ($ItemNode in $ConditionNode.ChildNodes) {
                                    $ChildNode = $ObjectNode.GetChildNode($ItemNode.Name) # Items are not necessarily required
                                    if ($ChildNode) { TestObject $ChildNode $PropertyNode }
                                }
                            }
                            else {
                                "Expected $($ObjectNode.Path) to be a list node, but got a map node."
                            }
                        }
                        elseif ($ObjectNode -is [PSListNode]) {
                            if ($SchemaNode -is [PSListNode]) {
                                $Index = 0
                                foreach ($ItemNode in $ConditionNode.ChildNodes) {
                                    $ChildNode = $ObjectNode.GetChildNode($Index) # Items are not necessarily required
                                    if ($ChildNode) { TestObject $ChildNode $PropertyNode }
                                }
                            }
                            else {
                                "Expected $($ObjectNode.Path) to be a map node, but got a list node."
                            }
                        }
                        else {
                            "Expected $($ObjectNode.Path) to contain items, but got a leaf node."
                        }
                    }
                }
                if ($Test) { Write-Host $Test }
            }
        }
        $SchemaNode = [PSNode]::ParseInput($SchemaObject)
    }

    process {
        $ObjectNode = [PSNode]::ParseInput($InputObject, $MaxDepth)
        TestObject
    }
}