<#
.SYNOPSIS
    Deserializes a PowerShell expression to an object.

.DESCRIPTION
    The `ConvertFrom-Expression` cmdlet converts a PowerShell formatted expression to an object-graph existing of
    a mixture of nested arrays, hashtables and objects that contain a list of strings and values.

.PARAMETER InputObject
    Specifies the PowerShell expressions to convert to objects. Enter a variable that contains the string,
    or type a command or expression that gets the string. You can also pipe a string to ConvertFrom-Expression.

    The **InputObject** parameter is required, but its value can be an empty string.
    The **InputObject** value can't be `$null` or an empty string.

.PARAMETER LanguageMode
    Defines which object types are allowed for the deserialization, see: [About language modes][2]

    * Any type that is not allowed by the given language mode, will be omitted leaving a bare `[ValueType]`,
      `[String]`, `[Array]` or `[HashTable]`.
    * Any variable that is not `$True`, `$False` or `$Null` will be converted to a literal string, e.g. `$Test`.

    > [!Caution]
    >
    > In full language mode the concerned string will simply be invoke using [Invoke-Expression].
    >
    > Take reasonable precautions when using the Invoke-Expression cmdlet in scripts. When using
    > `-LanguageMode Full` to run a command that the user enters, verify that the command is safe to run
    > before running it. In general, it is best to design your script with predefined input options,
    > rather than allowing freeform input.

#>
function ConvertFrom-Expression {
    [CmdletBinding()][OutputType([Object])] param(

        [Parameter(Mandatory = $true, ValueFromPipeLine = $True)]
        [Alias('Expression')][String]$InputObject,

        [ValidateScript({ $_ -ne 'NoLanguage' })]
        [PSLanguageMode]$LanguageMode = 'Restricted'
    )

    begin {
        function StopError($Exception, $Id = 'IncorrectArgument', $Group = [Management.Automation.ErrorCategory]::SyntaxError, $Object){
            if ($Exception -is [System.Management.Automation.ErrorRecord]) { $Exception = $Exception.Exception }
            elseif ($Exception -isnot [Exception]) { $Exception = [ArgumentException]$Exception }
            $PSCmdlet.ThrowTerminatingError([System.Management.Automation.ErrorRecord]::new($Exception, $Id, $Group, $Object))
        }

        if ($this.LanguageMode -eq 'NoLanguage') { Throw 'The language mode "NoLanguage" is not supported.' }
    }

    process {
        [PSDeserialize]::new($InputObject, $LanguageMode).Object
    }
}