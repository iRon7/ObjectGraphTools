#Requires -Modules @{ModuleName="Pester"; ModuleVersion="5.0.0"}

Describe 'Sort-ObjectGraph' {

    BeforeAll {

        Set-StrictMode -Version Latest

        $FileInfo = [System.Io.FileInfo]$PSCommandPath
        $SourceFolder = Join-Path $FileInfo.Directory.Parent 'Source'
        Foreach ($SubFolder in 'Classes', 'Private') {
            $Folder = Join-Path $SourceFolder $SubFolder
            $PSScripts = Get-ChildItem $Folder -Filter *.ps1
            foreach ($PSScript in $PSScripts) { . $PSScript.FullName }
        }
        $PublicFolder =  Join-Path $SourceFolder Public
        $PSScriptPath = Join-Path $PublicFolder $FileInfo.Name.Replace('.Tests.ps1', '.ps1')
        . $PSScriptPath

    }

    Context 'Sanity Check' {

         It 'Help' {
             Sort-ObjectGraph -? | Out-String -Stream | Should -Contain SYNOPSIS
         }
    }

    Context 'Sort' {

        It 'Type' {
            $Object = @{
                String = 'String'
                HereString = @'
Hello
World
'@
                Int = 67
                Double = 1.2
                Long = 1234567890123456
                DateTime = [datetime]'1963-10-07T17:56:53.8139055'
                Version = [version]'1.2.34567.890'
                Guid = [guid]'5f167621-6abe-4153-a26c-f643e1716720'
                Script = {2 * 3}
                Array =
                    'One',
                    'Two',
                    'Three',
                    'Four'
                ByteArray =
                    1,
                    2,
                    3
                StringArray =
                    'One',
                    'Two',
                    'Three'
                EmptyArray = @()
                SingleValueArray = ,'one'
                SubArray =
                    'One',
                    (
                        'Two',
                        'Three'
                    ),
                    'Four'
                HashTable = @{ Name = 'Value' }
                Ordered = [ordered]@{
                    One = 1
                    Two = 2
                    Three = 3
                    Four = 4
                }
                Object = [pscustomobject]@{ Name = 'Value' }
            }

            { $Object | Sort-ObjectGraph } | Should -not -throw
        }

    }
}
