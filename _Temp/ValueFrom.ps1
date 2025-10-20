function Test-Length {
    param (
        [Parameter(
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [int]
        $Length
    )
    process {
        Write-Host "Length: '$($Length)'"
    }
}

Read-Host 'Input a length (e.g.: 42)' | Test-Length

function Test-MyLength {
    param (
        [Parameter(
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [int]
        $MyLength
    )
    process {
        Write-Host "MyLength: '$($MyLength)'"
    }
}

Read-Host 'Input a length (e.g.: 42)' | Test-MyLength
