#!/bin/pwsh

param(
    [Parameter(Mandatory = $true)]
    [string] $Path,
    [Parameter(Mandatory = $true)]
    [string] $OutputPath
)

if (-not (Test-Path -Path $Path))
{
    throw "File '${Path}' not found."
}

Write-Host "Merging list from '${Path}'..."

$json = Get-Content -Path $Path | ConvertFrom-Json
$merged = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

foreach ($list in $json.PSObject.Properties)
{
    $listName = $list.Name
    $listUrl = $list.Value

    Write-Host "Merging list '${listName}'..."
    $content = (Invoke-WebRequest -Uri $listUrl -UseBasicParsing).Content
    $lines = $content -split '\r?\n' | Where-Object {
        -not [string]::IsNullOrWhiteSpace($_) `
            -and -not $_.StartsWith('!') `
            -and -not $_.StartsWith('[Ad') `
            -and -not $_.Contains('+js') `
            -and -not $_.Contains('$important') `
            -and -not $_.Contains('$xhr') `
            -and -not $_.Contains('$1p') `
            -and -not $_.Contains('$3p')
    }
    foreach ($line in $lines)
    {
        $merged.Add($line) | Out-Null
    }
}

Write-Host "Writing $($merged.Count) merged rules..."

$header = @"
[Adblock Plus 3.6]
! Title: Metrokoto Combined List
! Updated: $((Get-Date).ToUniversalTime().ToString('o'))
! Version : $((Get-Date).ToUniversalTime().ToString('o'))
! Expires: 2 days (update frequency)
! License: https://www.gnu.org/licenses/gpl-3.0.html
! Homepage: https://github.com/Metrokoto/combined-abp-filters
! URL: https://github.com/Metrokoto/combined-abp-filters/releases/download/latest/merged.txt
"@

$header | Out-File -FilePath $OutputPath -Encoding UTF8
$merged | Sort-Object | Out-File -FilePath $OutputPath -Encoding UTF8 -Append

Write-Host 'Done.'
