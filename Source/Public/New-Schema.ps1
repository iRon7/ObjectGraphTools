function New-Schema {
    [CmdletBinding(HelpUri='https://github.com/iRon7/ObjectGraphTools/blob/main/Docs/New-Schema.md')][OutputType([String])] param(

        [Parameter(Mandatory = $true, ValueFromPipeLine = $True)]
        $InputObject
    )

    begin {
        function GetSchema([PSNode]$Node, $Parent) {
            # if ($PSVersionTable.PSVersion.Major -eq 5) {
            #     try { [void][Newtonsoft.Json.JsonConverter] }
            #     catch { Add-Type -Path "$PSScriptRoot/Assembly/Newtonsoft.Json.dll" }
            # }
        }
    }

    process {
        # $Schema = @{}
        # $Node = [PSNode]::parse($InputObject)
        # GetSchema $Node
        [Newtonsoft.Json.Schema]::Create()
        [Newtonsoft.Json.Schema.JsonSchema]::JsonSchema()
        [Microsoft.AnalysisServices.Tabular]::new()
    }

}

