class CommandName {
    hidden [string] $Alias = 'gci'
    [string] ToString() { return 'Get-ChildItem'    }
}

$CommandName = [CommandName]::new()
$CommandName        # yields Get-ChildItem
$CommandName.Alias  # yields gci