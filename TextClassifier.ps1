
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