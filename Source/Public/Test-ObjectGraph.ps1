<#
.SYNOPSIS
    Tests the properties of an object-graph.

.DESCRIPTION
    Tests an object-graph against a schema object by verifying that the properties of the object-graph
    meet the constrains defined in the schema object.
#>

# JsonSchema Properties
# Schema properties: [Newtonsoft.Json.Schema.JsonSchema]::New() | Get-Member
# https://www.newtonsoft.com/json/help/html/Properties_T_Newtonsoft_Json_Schema_JsonSchema.htm
# Enum PSSchemaName {
#     Title
#     Type
#     PrimaryKey # Should be red before items
#     Items
# }
function Test-ObjectGraph {
    [CmdletBinding(HelpUri='https://github.com/iRon7/ObjectGraphTools/blob/main/Docs/Test-ObjectGraph.md')][OutputType([String])] param(

        [Parameter(Mandatory = $true, ValueFromPipeLine = $True)]
        $InputObject,

        [Parameter(Mandatory = $true, Position = 0)]
        $SchemaObject,

        [Switch]$IsValid,

        [Switch]$ShowAll,

        [Alias('Depth')][int]$MaxDepth = [PSNode]::DefaultMaxDepth
    )



    begin {


        #  $NodeTypeCache = [System.Collections.Generic.Dictionary[String,NodeType]]::new()

        # $DefinitionOrder = @('Title', 'Type')

        function TestObject([PSNode]$ObjectNode, [PSMapNode]$SchemaNode, [Switch]$IsValid) {
            $Verbose = $VerbosePreference -in 'Stop', 'Continue', 'Inquire'
            if ($Verbose) { Write-Verbose $ObjectNode.Path }
            if (-not $IsValid) { $Violations = [Collections.Generic.List[Object]]::new() }
            $DefinitionNodes = @{}
            foreach ($ChildNode in $SchemaNode.ChildNodes) { $DefinitionNodes[$ChildNode.Name] = $ChildNode }
            foreach ($Name in @('Title', 'Type', 'List', 'Required', 'Optional')) {
                if (-not $DefinitionNodes.Contains($Name)) { continue }
                $DefinitionNode = $DefinitionNodes[$Name]
                $Definition = $DefinitionNode.Value
                if ($Verbose) { Write-Verbose "    Testing: $Name = $Definition" }
                $Expected, $Actual = $Null # Setting the $Actual will break the iteration
                $Checked = [Collections.Generic.HashSet[int]]::new()
                switch ($DefinitionNode.Name) {
                    Type {
                        $Type = $Definition -as [Type]
                        if (-not $Type) {
                            Throw "Schema error at $($SchemaNode.Path).Type: Unknown type [$Definition] in schema definition"
                        }
                        $Invalid = $ObjectNode.Value -isnot $Type
                        if ($IsValid -and $Invalid) { return $false }
                        if ($ShowAll -or $Invalid) { $Expected = "[$Definition] type" }
                        if ($Invalid) { $Actual = "$($ObjectNode.Value) of type [$($ObjectNode.ValueType)]" }
                    }
                    { $_ -in 'List', 'Required', 'Optional' } {
                        $Invalid = ($ObjectNode.NodeStructure -ne $DefinitionNode.NodeStructure)
                        if ($IsValid -and $Invalid) { return $false }
                        if ($ShowAll -or $Invalid) { $Expected = "$($DefinitionNode.NodeStructure) structure" }
                        if ($Invalid) { $Actual = "$($ObjectNode.Value) with $($ObjectNode.NodeStructure) structure" }
                    }
                    List {
                        if ($ObjectNode -isnot [PSCollectionNode]) { continue } # $ObjectNode and $DefinitionNode are already tested equal structures
                        if ($Definition -is [HashTable]) {
                            Throw "Schema error at $($SchemaNode.Path).List: Testing a map list requires an ordered dictionary or PSCustomObject."
                        }
                        if ($ObjectNode.Value -is [HashTable]) {
                            $Expected = "an ordered dictionary or PSCustomObject"
                            $Actual = "'$($ObjectNode.Type)'"
                            break
                        }
                        $Index = 0
                        $DefinitionNodes = $DefinitionNode.ChildNodes
                        foreach ($ChildNode in $ObjectNode.ChildNodes) {
                            $DefinitionNode = $DefinitionNodes[$Index++]
                            $Invalid = $ObjectNode -is [PSMapNode] -and $ObjectNode.Name -ne $DefinitionNode.Name
                            if ($IsValid -and $Invalid) { return $false }
                            if ($ShowAll -or $Invalid) { $Expected = "node #$Index named '$($DefinitionNode.Name)'" }
                            if ($Invalid) { $Actual = "'$($ObjectNode.Name)'" }
                            else {
                                $TestObject = TestObject $ChildNode $DefinitionNode $IsValid
                                if ($null -ne $TestObject) { $null = $Checked.add($Index) }
                                else { if ($IsValid) { Return $false } else { $Violations.AddRange($TestObject) } }
                            }
                        }
                    }
                    Required {
                        if ($ObjectNode -is [PSListNode]) { # $ObjectNode and $DefinitionNode are already tested equal structures
                            foreach ($RequiredNode in $DefinitionNode.ChildNodes) {
                                $Index = 0
                                $TestObject = $null
                                foreach ($ChildNode in $ObjectNode.ChildNodes) {
                                    if ($ChildNode -notin $Checked) {
                                        $TestObject = TestObject $ChildNode $RequiredNode -IsValid
                                        if ($TestObject) { $null = $Checked.add($Index) }
                                    }
                                    $Index++
                                }
                                $Invalid = $null -eq $TestObject
                                if ($IsValid -and $Invalid) { return $false }
                                if ($ShowAll -or $Invalid) { $Expected = $($RequiredNode.Value) }
                                if ($Invalid) { $Actual = "$($RequiredNode.Name) = $($RequiredNode.Value) doesn't exist" }
                            }
                        }
                        elseif ($ObjectNode -is [PSMapNode]) {
                            $Index = 0
                            foreach ($RequiredNode in $DefinitionNode.ChildNodes) {
                                $KeyExists = $ObjectNode.Contains($RequiredNode.Name)
                                if ($KeyExists) {
                                    $null = $Checked.add($Index)
                                    $ChildNode = $ObjectNode.GetChildNode($RequiredNode.Name)
                                    $TestObject = TestObject $ChildNode $RequiredNode $IsValid
                                    if ($null -ne $TestObject) { if ($IsValid) { Return $false } else { $Violations.AddRange(@($TestObject)) } }
                                }
                                $Invalid = -Not $KeyExists
                                if ($IsValid -and $Invalid) { return $false }
                                if ($ShowAll -or $Invalid) { $Expected = "containing '$($RequiredNode.Name)'" }
                                if ($Invalid) { $Actual = "'$($RequiredNode.Name)' doesn't exist" }
                                $Index++
                            }
                        }
                    }
                    Optional {
                        if ($ObjectNode -is [PSListNode]) { # $ObjectNode and $DefinitionNode are already tested equal structures
                            foreach ($OptionalNode in $DefinitionNode.ChildNodes) {
                                $Index = 0
                                foreach ($ChildNode in $ObjectNode.ChildNodes) {
                                    if ($ChildNode -notin $Checked) {
                                        $TestObject = TestObject $ChildNode $OptionalNode -IsValid
                                        if ($TestObject) { $Checked.add($Index) }
                                    }
                                    $Index++
                                }
                            }
                        }
                        elseif ($ObjectNode -is [PSMapNode]) {
                            $Index = 0
                            foreach ($OptionalNode in $DefinitionNode.ChildNodes) {
                                if ($ObjectNode.Contains($OptionalNode.Name)) {
                                    $null = $Checked.add($Index)
                                    $ChildNode = $ObjectNode.GetChildNode($RequiredNode.Name)
                                    $TestObject = TestObject $ChildNode $OptionalNode $IsValid
                                    if ($null -ne $TestObject) { if ($IsValid) { Return $false } else { $Violations.AddRange(@($TestObject)) } }
                                }
                                $Index++
                            }
                        }
                        $Invalid = $Checked.Count -lt $ObjectNode.Count
                        if ($IsValid -and $Invalid) { return $false }
                        if ($ShowAll -or $Invalid) { $Expected = "optional node" }
                        if ($Invalid) {
                            $Index = 0
                            $RedundantNames = foreach ($Node in $ObjectNode.ChildNodes) {
                                if ($Index++ -in $Checked) { continue }
                                $Node.Name
                            } -Join ', '
                            $Actual = "the following nodes are not optional: $RedundantNames"
                        }
                    }
                }
                if ($Expected) {
                    Write-Host 123
                    $Violations.Add(
                        [PSCustomObject]@{
                            Path     = $ObjectNode.Path
                            Value    = "$($ObjectNode.Value)"
                            Expected = $Expected
                            Actual   = $Actual
                        }
                    )
                    return $Violations
                }
            }
            if ($Violations) { $Violations }
        }

        $SchemaNode = [PSNode]::ParseInput($SchemaObject)
    }

    process {
        $ObjectNode = [PSNode]::ParseInput($InputObject, $MaxDepth)
        TestObject $ObjectNode $SchemaNode $IsValid
    }
}