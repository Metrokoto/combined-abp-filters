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
            -and -not $_.Contains('#$#') `
            -and -not $_.Contains('+js') `
            -and -not $_.Contains('$important') `
            -and -not $_.Contains('$xhr') `            
            -and -not $_.Contains('$all') `
            -and -not $_.Contains('$frame') `
            -and -not $_.Contains('$doc') `
            -and -not $_.Contains('$cname') `
            -and -not $_.Contains('$css') `
            -and -not $_.Contains('$denyallow') `
            -and -not $_.Contains('$from') `
            -and -not $_.Contains('$ghide') `
            -and -not $_.Contains('$ehide') `
            -and -not $_.Contains('$inline-script') `
            -and -not $_.Contains('$inline-font') `
            -and -not $_.Contains('$ipaddress') `
            -and -not $_.Contains('$method') `
            -and -not $_.Contains('$permissions') `
            -and -not $_.Contains('$specifichide') `
            -and -not $_.Contains('$shide') `
            -and -not $_.Contains('$strict1p') `
            -and -not $_.Contains('$strict3p') `
            -and -not $_.Contains('$to') `
            -and -not $_.Contains('$empty') `
            -and -not $_.Contains('$mp4') `
            -and -not $_.Contains('$redirect') `
            -and -not $_.Contains('$removeparam') `
            -and -not $_.Contains('$replace') `
            -and -not $_.Contains('$uritransform') `
            -and -not $_.Contains('$urlskip') `
            -and -not $_.Contains('$popunder') `
            -and -not $_.Contains('$*') `
            -and -not $_.Contains('$_') `
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
