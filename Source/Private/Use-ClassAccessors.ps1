<#PSScriptInfo
.Version 0.1.0
.Guid 19631007-aef4-42ec-9be2-1cc2854222cc
.Author Ronald Bode (iRon)
.CompanyName
.Copyright
.Tags Accessors Getter Setter Class get_ set_ TypeData
.License https://github.com/iRon7/Use-ClassAccessors/LICENSE.txt
.ProjectUri https://github.com/iRon7/Use-ClassAccessors
.Icon https://raw.githubusercontent.com/iRon7/Use-ClassAccessors/master/Use-ClassAccessors.png
.ExternalModuleDependencies
.RequiredScripts
.ExternalScriptDependencies
.ReleaseNotes
.PrivateData
#>

<#
    .SYNOPSIS
        Implements class getter and setter accessors.

    .DESCRIPTION
        The [Use-ClassAccessors][1] cmdlet updates script property of a class from the getter and setter methods.
        Which are also known as [accessors or mutator methods][2].

        The getter and setter methods should use the following syntax:

        ### getter syntax

            [<type>] get_<property name>() {
              return <variable>
            }

        or:

            [Object] get_<property name>() {
              return ,[<Type>]<variable>
            }
        ### setter syntax

            set_<property name>(<variable>) {
              <code>
            }

        > [!NOTE]
        > A **setter** accessor requires a **getter** accessor to implement the related property.

        > [!NOTE]
        > In most cases, you might want to hide the getter and setter methods using the [`hidden` keyword][3]
        > on the getter and setter methods.

    .EXAMPLE
        # Using class accessors

        The following example defines a getter and setter for a `value` property
        and a _readonly_ property for the type of the type of the contained value.

            Install-Script -Name Use-ClassAccessors

            Class ExampleClass {
                hidden $_Value
                hidden [Object] get_Value() {
                  return $this._Value
                }
                hidden set_Value($Value) {
                  $this._Value = $Value
                }
                hidden [Type]get_Type() {
                  if ($Null -eq $this.Value) { return $Null }
                  else { return $this._Value.GetType() }
                }
                hidden static ExampleClass() { Use-ClassAccessors }
            }

            $Example = [ExampleClass]::new()

            $Example.Value = 42         # Set value to 42
            $Example.Value              # Returns 42
            $Example.Type               # Returns [Int] type info
            $Example.Type = 'Something' # Throws readonly error

    .PARAMETER Class

        Specifies the class from which the accessor need to be initialized.
        Default: The class from which this function is invoked (by its static initializer).

    .PARAMETER Property

        Filters the property that requires to be (re)initialized.
        Default: All properties in the given class

    .PARAMETER Force

        Indicates that the cmdlet reloads the specified accessors,
        even if the accessors already have been defined for the concerned class.

    .LINK
        [1]: https://github.com/iRon7/Use-ClassAccessors "Online Help"
        [2]: https://en.wikipedia.org/wiki/Mutator_method "Mutator method"
        [3]: https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_classes#hidden-keyword "Hidden keyword in classes"
#>

param(
    [Parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [string[]]$Class,

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$Property,

    [switch]$Force
)

process {
    $ClassNames =
        if ($Class) { $Class }
        else {
            $Caller = (Get-PSCallStack)[1]
            if ($Caller.FunctionName -ne '<ScriptBlock>') {
                $Caller.FunctionName
            }
            elseif ($Caller.ScriptName) {
                $Ast = [System.Management.Automation.Language.Parser]::ParseFile($Caller.ScriptName, [ref]$Null, [ref]$Null)
                $Ast.EndBlock.Statements.where{ $_.IsClass }.Name
            }
        }
    foreach ($ClassName in $ClassNames) {
        $TargetType = $ClassName -as [Type]
        if (-not $TargetType) { Write-Warning "Class not found: $ClassName" }
        $TypeData = Get-TypeData -TypeName $ClassName
        $Members = if ($TypeData -and $TypeData.Members) { $TypeData.Members.get_Keys() } else { @() }
        $Methods =
            if ($Property) {
                $TargetType.GetMethod("get_$Property")
                $TargetType.GetMethod("set_$Property")
            }
            else {
                $targetType.GetMethods().where{ ($_.Name -Like 'get_*' -or  $_.Name -Like 'set_*') -and $_.Name -NotLike '???__*' }
            }
        $Accessors = @{}
        foreach ($Method in $Methods) {
            $Member = $Method.Name.SubString(4)
            if (-not $Force -and $Member -in $Members) { continue }
            $Parameters = $Method.GetParameters()
            if ($Method.Name -Like 'get_*') {
                if ($Parameters.Count -eq 0) {
                    if ($Method.ReturnType.IsArray) {
                        $Expression = @"
`$TargetType = '$ClassName' -as [Type]
`$Method = `$TargetType.GetMethod('$($Method.Name)')
`$Invoke = `$Method.Invoke(`$this, `$Null)
`$Output = `$Invoke -as '$($Method.ReturnType.FullName)'
if (@(`$Invoke).Count -gt 1) { `$Output } else { ,`$Output }
"@
                    }
                    else {
                        $Expression = @"
`$TargetType = '$ClassName' -as [Type]
`$Method = `$TargetType.GetMethod('$($Method.Name)')
`$Method.Invoke(`$this, `$Null) -as '$($Method.ReturnType.FullName)'
"@
                    }
                    if (-not $Accessors.Contains($Member)) { $Accessors[$Member] = @{} }
                    $Accessors[$Member].Value = [ScriptBlock]::Create($Expression)
                }
                else { Write-Warning "The getter '$($Method.Name)' is skipped as it is not parameter-less." }
            }
            elseif ($Method.Name -Like 'set_*') {
                if ($Parameters.Count -eq 1) {
                    $Expression = @"
`$TargetType = '$ClassName' -as [Type]
`$Method = `$TargetType.GetMethod('$($Method.Name)')
`$Method.Invoke(`$this, `$Args)
"@
                    if (-not $Accessors.Contains($Member)) { $Accessors[$Member] = @{} }
                    $Accessors[$Member].SecondValue = [ScriptBlock]::Create($Expression)
                }
                else { Write-Warning "The setter '$($Method.Name)' is skipped as it does not have a single parameter" }
            }
        }
        foreach ($MemberName in $Accessors.get_Keys()) {
            $TypeData = $Accessors[$MemberName]
            if ($TypeData.Contains('Value')) {
                $TypeData.TypeName   = $ClassName
                $TypeData.MemberType = 'ScriptProperty'
                $TypeData.MemberName = $MemberName
                $TypeData.Force      = $Force
                Update-TypeData @TypeData
            }
            else { Write-Warning "A 'set_$MemberName()' accessor requires a 'get_$MemberName()' accessor." }
        }
    }
}
