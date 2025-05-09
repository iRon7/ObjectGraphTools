using module .\..\..\..\ObjectGraphTools

using namespace System.Management.Automation
using namespace System.Management.Automation.Language

Class PSDeserialize {
    hidden static [String[]]$Parameters = 'LanguageMode', 'ArrayType', 'HashTableType'
    hidden static PSDeserialize() { Use-ClassAccessors }

    hidden $_Object
    [PSLanguageMode]$LanguageMode = 'Restricted'
    [Type]$ArrayType     = 'Array'     -as [Type]
    [Type]$HashTableType = 'HashTable' -as [Type]
    [String] $Expression

    PSDeserialize([String]$Expression) { $this.Expression = $Expression }
    PSDeserialize(
        $Expression,
        $LanguageMode  = 'Restricted',
        $ArrayType     = $Null,
        $HashTableType = $Null
    ) {
        if ($this.LanguageMode -eq 'NoLanguage') { Throw 'The language mode "NoLanguage" is not supported.' }
        $this.Expression    = $Expression
        $this.LanguageMode  = $LanguageMode
        if ($Null -ne $ArrayType)     { $this.ArrayType     = $ArrayType }
        if ($Null -ne $HashTableType) { $this.HashTableType = $HashTableType }
    }

    hidden [Object] get_Object() {
        if ($Null -eq $this._Object) {
            $Ast = [System.Management.Automation.Language.Parser]::ParseInput($this.Expression, [ref]$null, [ref]$Null)
            $this._Object = $this.ParseAst([Ast]$Ast)
        }
        return $this._Object
    }

    hidden [Object] ParseAst([Ast]$Ast) {
        # Write-Host 'Ast type:' "$($Ast.getType())"
        $Type = $Null
        if ($Ast -is [ConvertExpressionAst]) {
            $FullTypeName = $Ast.Type.TypeName.FullName
            if (
                $this.LanguageMode -eq 'Full' -or (
                    $this.LanguageMode -eq 'Constrained' -and
                    [PSLanguageType]::IsConstrained($FullTypeName)
                )
            ) {
                try { $Type = $FullTypeName -as [Type] } catch { write-error $_ }
            }
            $Ast = $Ast.Child
        }
        if ($Ast -is [ScriptBlockAst]) {
            $List = [List[Object]]::new()
            if ($Null -ne $Ast.BeginBlock)   { $Ast.BeginBlock.Statements.ForEach{ $List.Add($this.ParseAst($_)) } }
            if ($Null -ne $Ast.ProcessBlock) { $Ast.ProcessBlock.Statements.ForEach{ $List.Add($this.ParseAst($_)) } }
            if ($Null -ne $Ast.EndBlock)     { $Ast.EndBlock.Statements.ForEach{ $List.Add($this.ParseAst($_)) } }
            if ($List.Count -eq 1) { return $List[0] } else { return @($List) }
        }
        elseif ($Ast -is [PipelineAst]) {
            $Elements = $Ast.PipelineElements
            if (-not $Elements.Count)  { return @() }
            elseif ($Elements -is [CommandAst]) {
                return $Null #85 ConvertFrom-Expression: convert function/cmdlet calls to Objects
            }
            elseif ($Elements.Expression.Count -eq 1) { return $this.ParseAst($Elements.Expression[0]) }
            else { return $Elements.Expression.Foreach{ $this.ParseAst($_) } }
        }
        elseif ($Ast -is [ArrayLiteralAst] -or $Ast -is [ArrayExpressionAst]) {
            if (-not $Type -or 'System.Object[]', 'System.Array' -eq $Type.FullName) { $Type = $this.ArrayType }
            if ($Ast -is [ArrayLiteralAst]) { $Value = $Ast.Elements.foreach{ $this.ParseAst($_) } }
            else { $Value = $Ast.SubExpression.Statements.foreach{ $this.ParseAst($_) } }
            if ('System.Object[]', 'System.Array' -eq $Type.FullName) {
                if ($Value -isnot [Array]) { $Value = @($Value) } # Prevent single item array unrolls
            }
            else { $Value = $Value -as $Type }
            return $Value
        }
        elseif ($Ast -is [HashtableAst]) {
            if (-not $Type -or $Type.FullName -eq 'System.Collections.Hashtable') { $Type = $this.HashTableType }
            $IsPSCustomObject = "$Type" -in
                'PSCustomObject',
                'System.Management.Automation.PSCustomObject',
                'PSObject',
                'System.Management.Automation.PSObject'
            if ($Type.FullName -eq 'System.Collections.Hashtable') { $Map = @{} } # Case insensitive
            elseif ($IsPSCustomObject) { $Map = [Ordered]@{} }
            else { $Map = New-Object -Type $Type }
            $Ast.KeyValuePairs.foreach{
                if ( $Map -is [Collections.IDictionary]) { $Map.Add($_.Item1.Value, $this.ParseAst($_.Item2)) }
                else { $Map."$($_.Item1.Value)" = $this.ParseAst($_.Item2) }
            }
            if ($IsPSCustomObject) { return [PSCustomObject]$Map } else { return $Map }
        }
        elseif ($Ast -is [ConstantExpressionAst]) {
            if ($Type) { $Value = $Ast.Value -as $Type } else { $Value = $Ast.Value }
            return $Value
        }
        elseif ($Ast -is [VariableExpressionAst]) {
            $Value = switch ($Ast.VariablePath.UserPath) {
                Null        { $Null }
                True        { $True }
                False       { $False }
                PSCulture   { (Get-Culture).ToString() }
                PSUICulture { (Get-UICulture).ToString() }
                Default     { $Ast.Extent.Text }
            }
            return $Value
        }
        else { return $Null }
    }
}
