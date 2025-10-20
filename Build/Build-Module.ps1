using namespace System.Collections
using namespace System.Collections.Generic
using namespace System.Collections.Specialized
using namespace System.Collections.ObjectModel
using namespace System.IO
using namespace System.Link
using namespace System.Text
using NameSpace System.Management.Automation
using NameSpace System.Management.Automation.Language

<#
.SYNOPSIS
Module Builder

.DESCRIPTION
Build a new module (`.psm1`) file from a folder containing PowerShell scripts (`.ps1` files) and other resources.

This module builder doesn't take care of the module manifest (`.psd1`) file, but it simply build the module file
from the scripts and resources in the specified folder while taking of the following:

* merging the statements (e.g. `#Requires` and `using` statements)
* preventing duplicates and collisions (e.g. duplicate function names)
* Ordering the statements based on their dependencies (e.g. classes inheritance)
* formatting the output.

It doesn't touch any module settings defined in the module manifest, such as the module Version, NestedModules and
ScripsToProcess. The only requirement is that the following settings are **not** defined (or commented out):

* ~~FunctionsToExport = @()~~
* ~~VariablesToExport = @()~~
* ~~AliasesToExport = @()~~

These particular settings are automatically generated based on the cmdlets, variables and aliases defined in the
source scripts and eventually handled by the module (`.psm1`) file.

The general consensus behind this module builder is that the module author defines the items that should be
**loaded** (imported) by [`Import-Module`] meaning that he shouldn't be concerned with *invoking* (dot-sourcing)
any scripts knowing that this could lead to similar concerns as using the [`Invoke-Expression`] cmdlet especially
when working in a team.
See also [https://github.com/PowerShell/PowerShell/issues/18740].

This means that this module builder will only accept specific statements (blocks) and reject (with a warning) on
statements that require any invocation which potentially could lead to conflicts with other functions and types.

## Statements that are accepted

The accepted statements might be divided into different files and (sub)folders using any file name or folder name
with the exception of functions that need to be exported as cmdlets.

The accepted statement types are categorized and loaded in the following order:
* [Requirements]
* [using statements]
* [enum types]
* [Classes]
* [Variables assignments]
* [(private) Functions]
* [(public) Cmdlets]
* [Aliases]
* [Format files]

### Requirements

The module builder will merge the `#Requires` statements from the source scripts and will add them to the top of
the module file.

#### #Required -Version

If multiple `#required -version` statements are found, the highest version will be used.

#### #Required -PSEdition

If conflicting `#required -PSEdition` statements are found, a merge conflict exception is thrown.

#### #Required -Modules

If multiple `#required -Modules` statements are found, the module names will be merged and the highest version

#### #Required -RunAsAdministrator

If set in any script, the module builder will add the `#Requires -RunAsAdministrator` statement to the top of the
module file.

> [!TIP]
> Consider to make your function [self-elevating](https://stackoverflow.com/q/60209449/1701026).

### Using statements

In general `using` statements are merged and added to the module file except for the `using module` with will be
rejected and a warning will be shown.

#### using namespace <.NET-namespace>

The module builder will use the full namespace name and added or merged them accordingly.

#### using module <module-name>

The module builder will reject this statement and will suggest to use the module manifest instead.

#### using assembly <assembly-name>

The module builder will reformat the assembly path and merge the assembly names and add them to module file.

### Enum types

`Enum` and `Flags` types are reformatted using the explicit item value and added or merged them accordingly.

> [!NOTE]
> All types are [automatically added to the TypeAccelerators list][2] to make sure they are publicly available.

### Classes

`Class` definitions are sorted based on any derived (custom) class dependency and added or accordingly.
If conflicting there are multiple classes with the same name a merge conflict exception is thrown unless the
content of the class is exactly the same.

> [!NOTE]
> All types are [automatically added to the TypeAccelerators list][2] to make sure they are publicly available.

> [!WARNING]
> PowerShell classes do have some known [limitation][3] and know [issues][4] that might cause problems when using
> a module builder. For example, when dividing classes that are depended of each other over multiple files would
> lead to "*Unable to find type [<typename>]*" in the "PROBLEMS" tab. The only solution is to put these classes
> in the same file or neglect the specific problem.

### Variables assignments

The module builder will merge the variable assignments and add export them when the module is loaded.

> [!TIP]
> For variables that are dynamically assigned during module load time, consider to use the `ScriptsToProcess`
> setting in the module manifest instead or define the variable during the concerned function or class execution.

### (Private) Functions

Any function that is defined in the source scripts will be added to the module file as a private function.
Meaning the function will not be exported by the module builder and will not be available to the user
when the module is loaded. The function will only be available to other functions in the module file.
To export a function as a cmdlet, the function needs to be defined in a script file with the `.ps1` extension,
see: [(public) cmdlets].

### (Public) cmdlets

Any (public) function that needs to be exported by the module builder is called a [cmdlets][5] in this design.
The module builder will recognize any PowerShell script file (`.ps1`) that contains a `param` block and will treat
it as a cmdlet. The name of the script file will be used as the cmdlet name. Any `Required` or `Using` statement
will be merged and added to the module file.

This module builder design enforces the use of advanced functions and prevents coincidentally interfering with
other cmdlets or other items in the module framework. See also [Add `ScriptsToInclude` to the Module Manifest][4].

### Aliases

This module builder only supports aliases for (public) cmdlets (exported functions). A cmdlet alias might be set
using the [Alias Attribute Declaration][6], this will export the alias when the module is loaded.

> [!NOTE]
> The [Set-Alias] command statement is rejected as aliases should be avoided for private functions as they can
> make code difficult to read, understand and impact availability (see: [AvoidUsingCmdletAliases][7]).

### Format files

The module builder will accept PowerShell format files (`.ps1xml`) and will merge the view definitions.
For more details on formatting views, see: [about Types.ps1xml][8].

.EXAMPLE
# (Re)build a new module file

Build a new module file from the scripts in the `.\Scripts` folder and save it to `.\MyModule.psm1`.

    Build-Module -SourceFolder .\Scripts -ModulePath .\MyModule.psm1

.PARAMETERS SourceFolder

The source folder containing the PowerShell scripts and resources to build the module from.

.PARAMETERS ModulePath

The path to the module file to create.

> [!WARNING]
> The module file will be overwritten if it already exists.

.PARAMETERS Depth

The depth of the source folder structure to search for scripts and resources. Default is `1`.

.LINK
[1]: https://learn.microsoft.com/powershell/scripting/developer/cmdlet/cmdlet-overview "cmdlet overview"
[2]: https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_classes#exporting-classes-with-type-accelerators "Exporting classes with type accelerators"
[3]: https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_classes#limitations "Class limitations"
[4]: https://github.com/PowerShell/PowerShell/issues/6652 "Various PowerShell Class Issues"
[5]: https://github.com/PowerShell/PowerShell/issues/24253 "Add ScriptsToInclude to the Module Manifest"
[6]: https://learn.microsoft.com/powershell/scripting/developer/cmdlet/alias-attribute-declaration "Alias Attribute Declaration"
[7]: https://learn.microsoft.com/powershell/utility-modules/psscriptanalyzer/rules/avoidusingcmdletaliases "Avoid using cmdlet aliases"
[8]: https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_types.ps1xml "about Types.ps1xml"
#>

param(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)][String]$SourceFolder,
    [Parameter(Mandatory = $true)][String]$ModulePath,
    [Int]$Depth = 1
)

Begin {

    $Script:SourcePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($SourceFolder)

    function Use-Script([Alias('Name')][String]$ScriptName, [Alias('Version')][Version]$ScriptVersion) {
        $Command = Get-Command $ScriptName -ErrorAction SilentlyContinue
        if (
            -not $Command -and
            -not ($ScriptVersion -and (Get-PSScriptFileInfo $Command.Source).Version -lt $ScriptVersion) -and
            -not (Install-Script $ScriptName -MinimumVersion $ScriptVersion -PassThru)
        ) {
            $MissingVersion = if ($ScriptVersion) { " version $ScriptVersion" }
            $ErrorRecord = [ErrorRecord]::new(
                "Missing command: '$ScriptName'$MissingVersion.",
                'MissingScript', 'InvalidArgument', $ScriptName
            )
            $PSCmdlet.ThrowTerminatingError($ErrorRecord)
        }
    }

    Use-Script -Name Sort-Topological -Version 0.1.2

    function New-LocationMessage([String]$Message, [String]$FilePath, $Target) {
        if ($Message -like '*.' -and $Message -notlike '*..') { $Message = $Message.Remove($Message.Length - 1) }
        $Return = "$([char]0x1b)[7m$Message$([char]0x1b)[27m"
        $Extent = if ($Target -is [AST] -and $Target.Extent -is [IScriptExtent]) { $Target.Extent } else { $Target }
        $Text, $Column, $Line =
            if ($Extent -is [IScriptExtent]) { $Extent.Text, $Extent.StartColumnNumber, $Extent.StartLineNumber}
            elseif ($Extent -is [PSToken])   { $Extent.Content, $Extent.StartColumn, $Extent.StartLine }
            else { $Extent }
        $Location = $($FilePath, $line, $Column).where{ $_ } -join '.'
        if ($Null -ne $Text)   {
            if ($Text.Length -gt 128) { $Text = $Text.SubString(0, 128) }
            $Text = $Text -replace '\s+', ' '
            if ($Text.Length -gt 64) { $Text = $Text.SubString(0, 61) + '...' }
            if ($Location) { $Location += ": $Text" }
        }
        if ($Location) { $Return += " $Location" }
        return $Return
    }

    function New-ModuleError($ErrorRecord, $Module, $FilePath, $Extent) {
        $Id       = if ($ErrorRecord -is [ErrorRecord]) { $ErrorRecord.FullyQualifiedErrorId } else { 'ModuleBuildError' }
        $Category = if ($ErrorRecord -is [ErrorRecord]) { $ErrorRecord.CategoryInfo.Category } else { 'ParserError' }

        $Message = New-LocationMessage $ErrorRecord $FilePath $Extent
        [ErrorRecord]::new($Message, $Id, $Category, $Module)
    }


    class NameSpaceName {
        hidden static [HashSet[String]]$SystemName = [HashSet[String]]::new([String[]]@(([Type]'Type').NameSpace), [StringComparer]::InvariantCultureIgnoreCase)
        hidden [String] $_Name

        NameSpaceName([String]$Name) { $this._Name = $Name }

        [String] ToString() {
            $Name = if ($this._Name -Like 'System.*') { [NameSpaceName]::SystemName -eq $this._Name }
                    else { [NameSpaceName]::SystemName  -eq "System.$($this._Name)"}
            if ($Name) { return $Name }
            return (Get-Culture).TextInfo.ToTitleCase($this._Name)
        }
    }

    class Collision: Exception { Collision([string]$Message): base ($Message) {} }
    class Omission: Exception { Omission([string]$Message): base ($Message) {} }

    class ModuleRequirements {
        [Version]$Version
        [String]$PSEdition
        [OrderedDictionary]$Modules = [OrderedDictionary]::new([StringComparer]::InvariantCultureIgnoreCase)
        [Bool]$RunAsAdministrator

        hidden [String[]]get_Values() {
            return $(
                if ($this.Version) { "#Requires -Version $($this.Version.ToString(2))" }
                if ($this.PSEdition) { "#Requires -PSEdition $($this.PSEdition -join ', ')" }
                if ($this.Modules) {
                    foreach ($Name in $this.Modules.Keys) {
                        if ($this.Modules[$Name].Count) { # parse hashtable
                            "#Requires -Modules @{ ModuleName = '$Name'; $(
                                $(foreach ($Key in $this.Modules[$Name].Keys) {
                                    "$Key = '$($this.Modules[$Name][$Key])'"
                                }) -Join '; '
                            ) }"
                        }
                        else { "#Requires -Modules '$Name'" }
                    }
                }
                if ($this.RunAsAdministrator) { "#Requires -RunAsAdministrator" }
            )
        }

        Add([ScriptRequirements]$Requirements) {
            if ($Requirements.RequiredPSVersion -gt $this.Version) {
                $this.Version = $Requirements.RequiredPSVersion
            }
            if ($Requirements.RequiredPSEditions) {
                $Sorted = [Linq.Enumerable]::Order($Requirements.RequiredPSEditions)
                if (
                    $this.PSEdition -and
                    -not [Linq.Enumerable]::SequenceEqual($this.PSEdition, $Sorted)
                ) { throw [Collision]"Merge conflict with required edition '$($this.PSEdition)'" }
                $this.PSEdition = $Sorted
            }
            if ($Requirements.RequiredModules) {
                if (-not $this.Modules) { $this.Modules = @{} }
                foreach ($RequiredModule in $Requirements.RequiredModules) {
                    $Name = $RequiredModule.Name
                    if (-not $this.Modules[$Name]) { $this.Modules[$Name] = @{} }
                    $Module = $this.Modules[$Name]
                    if ($RequiredModule.Guid) {
                        if ($Module['Guid'] -and $RequiredModule.Guid -ne $Module['Guid']) {
                            throw [Collision]"Merge conflict with required module guid: [$($Module['Guid'])]"
                        }
                        $Module['Guid'] = $RequiredModule.Guid
                    }
                    if ($RequiredModule.Version) {
                        if ($Module['RequiredVersion']) {
                            throw [Collision]"Merge conflict with required module version '$($Module['RequiredVersion'])'"
                        }
                        if (
                            -not $Module['ModuleVersion'] -or
                            $RequiredModule.Version -gt $Module['ModuleVersion']
                        ) { $Module['ModuleVersion'] = $RequiredModule.Version }
                    }
                    if ($RequiredModule.MaximumVersion) {
                        if ($Module['RequiredVersion']) {
                            throw [Collision]"Merge conflict with required module version '$($Module['RequiredVersion'])'"
                        }
                        if (
                            -not $Module['MaximumVersion'] -or
                            $RequiredModule.MaximumVersion -lt $Module['MaximumVersion']
                        ) { $Module['MaximumVersion'] = $RequiredModule.MaximumVersion }
                    }
                    if ($RequiredModule.RequiredVersion) {
                        if ($Module['Version']) {
                            throw [Collision]"Merge conflict with minimal module version '$($Module['Version'])'"
                        }
                        if ($Module['MaximalVersion']) {
                            throw [Collision]"Merge conflict with maximal module version '$($Module['MaximalVersion'])'"
                        }
                        if (
                            $Module['RequiredVersion'] -and
                            $Module['RequiredVersion'] -ne $RequiredModule.MaximumVersion)
                         { throw [Collision]"Merge conflict with required module version '$($Module['RequiredVersion'])'" }
                        $Module['RequiredVersion'] = $RequiredModule.RequiredVersion
                    }
                }
            }
            if ($Requirements.IsElevationRequired) { $this.RunAsAdministrator = $true }
            if ($Requirements.Assembly) { throw 'The "#Requires -Assembly" syntax is deprecated.' }
        }
    }

    class ModuleUsingStatements {
        [HashSet[String]]$Namespace = [HashSet[String]]::new([StringComparer]::InvariantCultureIgnoreCase)
        [HashSet[String]]$Assembly  = [HashSet[String]]::new([StringComparer]::InvariantCultureIgnoreCase)

        hidden [String[]]get_Values() {
            return $(
                $this.Assembly.foreach{ "using assembly $_" }
                $this.Namespace.foreach{ "using namespace $_" }
            )
        }

        Add([UsingStatementAst]$UsingStatement) {
            # Try to unify similar items so that they will better merge.
            $Kind = $UsingStatement.UsingStatementKind.ToString()
            switch ($Kind) {
                Assembly {
                    $Name, $Details = $UsingStatement.Name.Value -Split '\s*,\s*'
                    if ($Details) { # Order details to merge duplicates
                        $Name += ', ' + (($Details -Replace '\s*=\s*', ' = ' | Sort-Object) -Join ', ')
                    }
                    $null = $this.Assembly.Add($Name)
                }
                Command { throw 'Not implemented.' }
                Module { throw [Omission]"Rejected 'using module' statement (use manifest instead)." }
                Namespace { $Null = $this.Namespace.Add([NameSpaceName]$UsingStatement.Name.Value) }
                Default { throw [Omission]"Rejected unknown using statement." }
            }
        }
    }

    class ModuleBuilder {
        static [String]$Tab = '    ' # Used for indenting cmdlet contents

        [string] $Path
        [String] $Name

        ModuleBuilder($Path) {
            $FullPath = [Path]::GetFullPath($Path)
            $Extension = [Path]::GetExtension($FullPath)
            if ($Extension -eq '.psm1') { $this.Path = $FullPath }
            elseif ([Directory]::Exists($FullPath)) {
                $this.Path = [Path]::Combine($FullPath, "$([Path]::GetFileName($Path)).psm1")
            }
            else { Throw "The module path '$Path' is not a folder or doesn't have a '.psm1' extension." }
            $this.Name = [Path]::GetFileNameWithoutExtension($this.Path)
        }

        [String]GetRelativePath([String]$Path) {
            $ToPath   = $Path -split '[\\\/]'
            $BasePath = [Path]::GetDirectoryName($this.Path) -split '[\\\/]'
            for ($i = 0; $i -lt $BasePath.Length; $i++) { if ($ToPath[$i] -ne $BasePath[$i]) { break } }
            $RelativePath = '..\' * ($BasePath.Length - $i)
            $RelativePath += $ToPath[$i..($ToPath.Length - 1)] -join [IO.Path]::DirectorySeparatorChar
            return $RelativePath
        }

        hidden [OrderedDictionary]$Sections = [OrderedDictionary]::new([StringComparer]::InvariantCultureIgnoreCase)

        AddRequirement([ScriptRequirements]$Requires) {
            if (-not $this.Sections['Requires']) { $this.Sections['Requires'] = [ModuleRequirements]::new() }
            try { $this.Sections['Requires'].Add($Requires) } catch { throw }
        }
        hidden CheckDuplicate([String]$Type, [String]$Name, $Value) {
            if ($this.Sections[$Type].Contains($Name)) {
                if ($this.Sections[$Type][$Name] -eq $Value) { throw [Omission]"Rejected duplicate: $Name." }
                else { throw [Collision]"Merge conflict with $Type $Name" }
            }
        }
        hidden AddStatement([String]$SectionName, [String]$StatementId, $Definition) {
            if (-not $this.Sections[$SectionName]) {
                $this.Sections[$SectionName] = [OrderedDictionary]::new([StringComparer]::InvariantCultureIgnoreCase)
            }
            try { $this.CheckDuplicate($SectionName, $StatementId, $Definition) } catch { throw }
            $this.Sections[$SectionName][$StatementId] = $Definition
        }
        AddStatement([StatementAst]$Statement) {
            switch ($Statement.GetType().Name) {
                UsingStatementAst {
                    if (-not $this.Sections['Using']) { $this.Sections['Using'] = [ModuleUsingStatements]::new() }
                    try { $this.Sections['Using'].Add($Statement) } catch { throw }
                }
                TypeDefinitionAst {
                    if ($Statement.TypeAttributes -bAnd 'Enum') {
                        $Flags = $Statement.Attributes.count -and $Statement.Attributes.TypeName.Name -eq 'Flags'
                        $MaxLength = [Linq.Enumerable]::max($Statement.Members.Name.foreach{ $_.Length })
                        $Value = 0
                        $Expression = $( # consistently format expression to reveal duplicates
                            if ($Flags) { "[Flags()] enum $($Statement.Name) {" } else { "enum $($Statement.Name) {" }
                            foreach ($Member in $Statement.Members) {
                                if ($Member.InitialValue) { $Value = $Member.InitialValue.Value }
                                "$([ModuleBuilder]::Tab)$($Member.Name)$(' ' * ($MaxLength - $member.Name.Length)) = $Value"
                                $Value++
                            }
                            '}'
                        ) -Join [Environment]::Newline
                        try { $this.AddStatement('Enum', $Statement.Name, $Expression) } catch { throw }
                    }
                    elseif ($Statement.TypeAttributes -bAnd 'Class') {
                        try { $this.AddStatement('Class', $Statement.Name, $Statement) } catch { throw }
                    }
                    else { throw [Omission]"Rejected type (use manifest instead)." }
                }
                AssignmentStatementAst {
                    $VariableName = $Statement.Left.VariablePath.UserPath
                    $Expression = $Statement.Right.Extent.Text
                    if ($VariableName -eq 'Null' ) { throw [Omission]'Rejected assignment to $Null.' }
                    try { $this.AddStatement('Variable', $VariableName, $Expression) } catch { throw }
                }
                FunctionDefinitionAst {
                    try { $this.AddStatement('Function', $Statement.Name, $Statement) } catch { throw }
                }
                Default { throw [Omission]"Rejected invalid module statement." }
            }
        }
        AddCmdlet([String]$Name, $Content) {
            $Tokens = [PSParser]::Tokenize($Content, [ref]$null)
            $AliasToken, $AliasGroupToken = $null
            $FunctionContent = [StringBuilder]::new()
            $Null = $FunctionContent.AppendLine("function $Name {")
            $Start = $Null
            for ($Index = 0; $Index -lt $Tokens.Count; $Index++) {
                if ($Null -eq $Start) {
                    While ($Index -lt $Tokens.Count -and $Tokens[$Index].Type -eq 'NewLine') { $Index++ }
                    $Start = $Tokens[$Index].Start
                }
                $Token = $Tokens[$Index]
                if ($Token.Type -eq 'Keyword' -and $Token.Content -eq 'param') { break}
                if ( # Omit the following tokens from the function content
                    ($Token.Type -eq 'Keyword' -and $Token.Content -eq 'using') -or
                    ($Token.Type -eq 'Comment' -and $Token.Content -match '^#Requires\s+-')
                ) {
                    $Null = $FunctionContent.Append($Content.SubString($Start, ($Token.Start - $Start)))
                    While ($Index -lt $Tokens.Count -and $Tokens[$Index].Type -ne 'NewLine') { $Index++ }
                    $Start = $Null
                    continue
                }
                if ($AliasToken) {
                    if ($AliasGroupToken) {
                        if ($Token.Type -eq 'String') {
                            $this.AddStatement('Alias', $Token.Content, $Name)
                            $AliasExists = Get-Alias $Token.Content -ErrorAction SilentlyContinue
                            if ($AliasExists -and  $AliasExists.Source -ne $this.Name) {
                                 Write-Warning "The alias '$($Token.Content)' ($($AliasExists.ResolvedCommand)) already exists."
                            }
                        }
                        elseif ($Token.Type -eq 'Operator' -and $Token.Content -eq ',') { <# continue #> }
                        elseif ($Token.Type -eq 'GroupEnd') { $AliasGroupToken = $null }
                        else { Throw "Expected Group-end token (')') in $($Name), line $($Token.StartLine), column $($Token.StartColumn)." }
                    }
                    elseif ($Token.Type -eq 'GroupStart') { $AliasGroupToken = $Token }
                    elseif ($Token.Type -eq 'Operator' -and $Token.Content -eq ']') { $AliasToken = $null }
                    else { Throw "Expected Attribute-end token (']') in $($Name), line $($Token.StartLine), column $($Token.StartColumn)." }
                }
                elseif ($Token.Type -eq 'Attribute' -and $Token.Content -eq 'Alias') { $AliasToken = $Token }
            }
            $Index = $Tokens.Count - 1
            while ($Index -gt 0 -and $Tokens[$Index].Type -eq 'NewLine') { $Index-- }
            $Length = $Tokens[$Index].Start + $Tokens[$Index].Length - $Start
            $Null = $FunctionContent.AppendLine($Content.SubString($Start, $Length))
            $Null = $FunctionContent.AppendLine('}')
            try { $this.AddStatement('Cmdlet', $Name, $FunctionContent.ToString()) } catch { throw }
        }
        AddFormat($SourceFile) {
            $RelativePath = $this.GetRelativePath($SourceFile)
            if (-not $this.Sections['Format']) {
                $this.Sections['Format'] = [OrderedDictionary]::new([StringComparer]::InvariantCultureIgnoreCase)
            }
            $Xml = [xml](get-Content $SourceFile)
            foreach ($Name in $Xml.Configuration.ViewDefinitions.View.Name) {
                if ($this.Sections['Format'].Contains($Name)) { throw [Collision]"Merge conflict with format '$Name'" }
                $this.Sections['Format'][$Name] = $RelativePath
            }
        }

        hidden [Bool]$SkipLine
        hidden [String]$CurrentRegion
        hidden [StringBuilder]$Content = [StringBuilder]::new()
        hidden AppendLine() { $null = $this.Content.AppendLine() }
        hidden AppendLine([String]$Line) {
            if ($Line.EndsWith([Char]10) -or $Line.EndsWith([Char]13)) { $null = $this.Content.Append($Line) }
            else { $null = $this.Content.AppendLine($Line) }
        }
        hidden AppendRegion ([String]$Name, [String[]]$Statements) {
            if ($this.Content.Length) { $this.AppendLine() } # Add line between sections
            $this.AppendLine("#Region $Name")
            $this.AppendLine()
            $Statements.foreach{ $this.AppendLine($_) }
            $this.AppendLine()
            $this.AppendLine("#EndRegion $Name")
        }
        Save() {
            $S = $this.Sections
            if ($S.Contains('Requires')) { $this.AppendRegion('Requires', $S.Requires.get_Values()) }
            if ($S.Contains('Using')) { $this.AppendRegion('Using', $S.Using.get_Values()) }
            if ($S.Contains('Variable')) { # https://github.com/PowerShell/PSScriptAnalyzer/issues/1950
                $Statements = $(
                    $this.AppendLine("[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification='https://github.com/PowerShell/PSScriptAnalyzer/issues/1950')]")
                    $this.AppendLine('param()')
                )
                $this.AppendRegion('Fix #1950', $Statements)
            }
            if ($S.Contains('Enum')) { $this.AppendRegion('Enum', $S.Enum.get_Values()) }
            if ($S.Contains('Class')) {
                $SortParams = @{
                    IdName = 'Name'
                    DependencyName = { $_.BaseTypes.TypeName.Name }
                    ErrorAction = 'SilentlyContinue'
                }
                $Classes = $S.Class.get_Values() | Sort-Topological @SortParams
                $this.AppendRegion('Class', $Classes.Extent.Text)
            }
            if ($S.Contains('Variable')) {
                $Statements = foreach($Name in $S.Variable.get_Keys()) { "`$${Name} = $($S.Variable[$Name])" }
                $this.AppendRegion('Variable', $Statements)
            }
            if ($S.Contains('Function')) { $this.AppendRegion('Function', $S.Function.get_Values()) }
            if ($S.Contains('Cmdlet')) { $this.AppendRegion('Cmdlet', $S.Cmdlet.get_Values()) }
            if ($S.Contains('Alias')) {
                $Aliases = [SortedDictionary[String,Object]]::new()
                foreach($Name in $S.Alias.get_Keys()) {
                    if (-not $Aliases.ContainsKey($Name)) { $Aliases[$Name] = [List[String]]::new() }
                    $Aliases[$Name].Add($S.Alias[$Name])
                }
                $Statements = foreach ($Name in $Aliases.Keys) { "Set-Alias -Name '$($Aliases[$Name])' -Value '$Name'" }
                $this.AppendRegion('Alias', $Statements)
            }
            if ($S.Contains('Format')) { # https://github.com/PowerShell/PowerShell/issues/17345
                # if (-not (Get-FormatData -ErrorAction Ignore $etsTypeName)) {
                # See: https://stackoverflow.com/a/67991167/1701026
                $Files = [OrderedDictionary]::new([StringComparer]::InvariantCultureIgnoreCase)
                foreach ($Name in $S.Format.get_Keys()) {
                    $FileName = $S.Format[$Name]
                    if (-not $S.Format.Contains($FileName)) { $Files[$FileName] = [List[String]]::new() }
                    $Files[$FileName].Add($Name)
                }
                $Formats = foreach ($FileName in $Files.get_Keys()) {
                    $Names = $Files[$FileName]
                    if($Names.Count -le 1) {
                        "if (-not (Get-FormatData '$Names' -ErrorAction Ignore)) {"
                    }
                    else {
                        $Names = @($Names).foreach{ "'$_'" } -join ', '
                        "if (-not @($Names).where({ Get-FormatData '`$_' -ErrorAction Ignore }, 'first')) {"
                    }
                    "    Update-FormatData -PrependPath `$PSScriptRoot\$FileName"
                    '}'
                }
                $this.AppendRegion('Format', $Formats)
            }

            $Export = @{ Cmdlet = 'Function'; Alias = 'Alias'; Variable = 'Variable' }
            $ModuleMembers = foreach ($Name in $Export.Keys) {
                $Member = $this.Sections[$Name]
                if ($Member.Count) { $Export[$Name] + ' = ' + ($Member.Keys.foreach{ "'$_'" } -join ', ') }
            }

            $ExportTypes = $(
                if ($this.Sections.Contains('Enum'))  { $this.Sections.Enum.get_Keys() }
                if ($this.Sections.Contains('Class')) { $this.Sections.Class.get_Keys() }
            )

            $Statements = $(
                if ($ModuleMembers.Count) {
                    '$ModuleMembers = @{'
                    $ModuleMembers.foreach{ "$([ModuleBuilder]::Tab)$_" }
                    '}'
                    'Export-ModuleMember @ModuleMembers'
                }

                if ($ExportTypes) {

                    '# https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_classes#exporting-classes-with-type-accelerators'
                    '# Define the types to export with type accelerators.'
                    '$ExportableTypes = @('
                    $ExportTypes.foreach{ "$([ModuleBuilder]::Tab)[$_]" }
                    ')'

                    {
$TypeAcceleratorsClass = [PSObject].Assembly.GetType('System.Management.Automation.TypeAccelerators')

foreach ($Type in $ExportableTypes) {
    if ($Type.FullName -notin $ExistingTypeAccelerators.Keys) {
        $TypeAcceleratorsClass::Add($Type.FullName, $Type)
    }
}

$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
    foreach($Type in $ExportableTypes) {
        $TypeAcceleratorsClass::Remove($Type.FullName)
    }
}.GetNewClosure()}.ToString()
                }
            )

            if ($Statements) { $this.AppendRegion('Export', $Statements) }

            Write-Verbose "Saving module content to '$($this.Path)'"
            Set-Content -LiteralPath $this.Path -Value $this.Content -NoNewline
        }
    }

    function Select-Statements($Statements, $SourceFile) {
        if (-Not $Statements) { return }
        foreach ($Statement in $Statements) {
            try {
                if ($Statement -is [ScriptRequirements]) { $Module.AddRequirement($Statement) }
                else { $Module.AddStatement($Statement) }
            }
            catch [Collision] { $PSCmdlet.ThrowTerminatingError((New-ModuleError $_ $Module $SourceFile $Statement)) }
            catch [Omission] { New-LocationMessage $_ $SourceFile $Statement | Write-Warning }
        }
    }

    $Module = try { [ModuleBuilder]::new($ModulePath) } catch { $PSCmdlet.ThrowTerminatingError($_) }
}

process {

    $SourceFiles = Get-ChildItem -Path $SourcePath -Depth $Depth -Include '*.ps1', '*.ps1xml'
    if (-not $SourceFiles) { $PSCmdlet.ThrowTerminatingError([ErrorRecord]::new("No valid script (.ps1) files found for '$SourcePath'", 'InvalidSourcePath', [ErrorCategory]::InvalidArgument, $null)) }

    foreach ($SourceFile in $SourceFiles) {
        $RelativePath = $Module.GetRelativePath($SourceFile)
        Write-Verbose "Processing '$RelativePath'"
        switch ([Path]::GetExtension($SourceFile)) {
            .ps1 {
                $Content = Get-Content -Raw $SourceFile.FullName
                $Ast = [Parser]::ParseInput($Content, [ref]$Null, [ref]$Null)
                Select-Statements $Ast.ScriptRequirements $RelativePath
                Select-Statements $Ast.UsingStatements $RelativePath
                if ($Ast.ParamBlock) { $Module.AddCmdlet($SourceFile.BaseName, $Content) }
                else { Select-Statements $Ast.EndBlock.Statements $RelativePath }
            }
            .ps1xml {
                $Module.AddFormat($SourceFile)
            }
        }
    }
}

end {
    $Module.Save()
}
