
<#
.Synopsis
   String to array of n-grams
.DESCRIPTION
   Given a String, returns an array of n-gram strings
.EXAMPLE
   Get-NGrams "This is a string!"
.EXAMPLE
   Get-NGrams "This is a string!" -n 3
.PARAMETER String
   The string to convert to an n-gram array
.PARAMETER n
   The number of characters in each n-gram (default 2)
#>
function Get-NGrams {
    param (
        [Parameter(Mandatory=$true)][string]$String,
        $n = 2
    )
    if ($n -gt $String.Length) { throw "string not long enough for $n-gram" }
    for ($i = 0; $i -le $String.Length - $n; $i++) {
        $String[$i..($i+$n-1)] -join ""
    }
}

function Featurize-String {
    param (
        [Parameter(Mandatory=$true)][string]$String,
        $MaxDimensions = 1000,
        $NGramMatch = '^\w+$'
    )
    $MD5 = New-Object System.Security.Cryptography.MD5CryptoServiceProvider
    $UTF8 = New-Object System.Text.UTF8Encoding
    $NGrams = Get-NGrams $String |
        Where-Object { $PSItem -match $NGramMatch }
    $VectorHash = @{}
    $NGrams | ForEach-Object {
        $StringHash =  $MD5.ComputeHash($UTF8.GetBytes($PSItem))
        # NOTE: Uint64 only holds the least-significant 64 bits of the md5 hash, but we're limiting dimensions so should be ok
        $Key = [System.BitConverter]::ToUInt64($StringHash, 8) % $MaxDimensions
        $VectorHash[$Key] += 1 / $NGrams.Count
    }
    $VectorHash.GetEnumerator() | ForEach-Object {
        @($PSItem.Key, $PSItem.Value)
    }
}

