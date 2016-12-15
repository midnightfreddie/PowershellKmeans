# Attempting to cluster/classify text posts
param (
    $AccordPath = "C:\tools\Accord.NET-3.3.0-libsonly\Release\net45",
    $Clusters = 4
)

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
        $NGramMatch = '^\w+$',
        $n = 2
    )
    $MD5 = New-Object System.Security.Cryptography.MD5CryptoServiceProvider
    $UTF8 = New-Object System.Text.UTF8Encoding
    $NGrams = Get-NGrams $String -n $n |
        Where-Object { $PSItem -match $NGramMatch }
    $VectorArray = @(0) * $MaxDimensions
    $NGrams | ForEach-Object {
        $StringHash =  $MD5.ComputeHash($UTF8.GetBytes($PSItem.ToLower()))
        # NOTE: Uint64 only holds the least-significant 64 bits of the md5 hash, but we're limiting dimensions so should be ok
        $Key = [System.BitConverter]::ToUInt64($StringHash, 8) % $MaxDimensions
        $VectorArray[$Key] += 1 / $NGrams.Count
    }
    @(,$VectorArray)
}

# Load Accord.MachineLearning dll
$MlDllPath = "$AccordPath\Accord.MachineLearning.dll"
Add-Type -Path $MlDllPath

$KMeans = New-Object Accord.MachineLearning.KMeans -ArgumentList $Clusters

$Json = Get-Content C:\temp\kmeanstest.json |
    ConvertFrom-Json

# $Json | select id, @{ Name = "body"; Expression = { $PSItem.data.body } }

$Vectors = $Json | ForEach-Object { @(,(Featurize-String $PSItem.data.body)) }

# This throws an error, but I think it's erroring out on converting data to output to Powershell; I think the functionality is working
$KMeans.Learn($Vectors)

$Labels = $KMeans.Clusters.Decide($Vectors)

$Out = [System.Collections.ArrayList]@()
for ($i = 0; $i -lt $Vectors.Count; $i++) { 
    $Out.Add((
        New-Object psobject -Property @{
            Cluster = $Labels[$i]
            Text = $Json[$i].data.body
        }
    )) | Out-Null
}

for ($i = 0; $i -lt $Clusters; $i++) { 
    "`n=== CLUSTER $i ===`n"
    $Out |
        Where-Object { $PSItem.Cluster -eq $i } |
        Select-Object -ExpandProperty Text
}
