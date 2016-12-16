# Attempting to cluster/classify text posts
param (
    $AccordPath = "C:\tools\Accord.NET-3.3.0-libsonly\Release\net45",
    $Clusters = 10
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
    $VectorArray = @($null) * $MaxDimensions
    $NGrams | ForEach-Object {
        $StringHash =  $MD5.ComputeHash($UTF8.GetBytes($PSItem.ToLower()))
        # NOTE: Uint64 only holds the least-significant 64 bits of the md5 hash, but we're limiting dimensions so should be ok
        $Key = [System.BitConverter]::ToUInt64($StringHash, 8) % $MaxDimensions
        $VectorArray[$Key] += 1 / $NGrams.Count
    }
    @(,$VectorArray)
}

function Get-TfIdf {
    param (
        [Parameter(Mandatory=$true)][string[]]$String,
        $MaxDimensions = 1000,
        $NGramMatch = '^\w+$',
        $n = 2
    )
    $NumDocsWithTerm = @(0) * $MaxDimensions
    $IDFt = @(0) * $MaxDimensions
    $VectorList = [System.Collections.ArrayList]@()
    $String | ForEach-Object {
        $Vector = Featurize-String $PSItem -MaxDimensions $MaxDimensions -NGramMatch $NGramMatch -n $n
        $VectorList.Add($Vector) | Out-Null
        for ($i = 0; $i -lt $MaxDimensions; $i++) {
            if ($Vector[$i]) { $NumDocsWithTerm[$i] ++ }
        }
    }
    $TotalDocs = $VectorList.Count
    for ($i = 0; $i -lt $MaxDimensions; $i++) {
        if ($NumDocsWithTerm[$i]) {
            $IDFt[$i] = [Math]::Log($TotalDocs / $NumDocsWithTerm[$i])
        }
    }
    $VectorList | ForEach-Object {
        $Out = @(0) * $MaxDimensions
        for ($i = 0; $i -lt $MaxDimensions; $i++) {
            $Out[$i] = $PSItem[$i] * $IDFt[$i]
        }
        @(,$Out)
    }
}

# Adapted from Richard Siddaway https://richardspowershellblog.wordpress.com/2011/07/12/standard-deviation/
function Get-StandardDeviation {
    [CmdletBinding()]
    param (
      [double[]]$numbers
    )

    $avg = $numbers |
        # Don't count null values
        Where-Object { $PSItem } |
        Measure-Object -Average |
        Select-Object Count, Average

    $popdev = 0

    foreach ($number in $numbers){
      $popdev +=  [math]::pow(($number - $avg.Average), 2)
    }

    $sd = [math]::sqrt($popdev / ($avg.Count-1))

    New-Object psobject -Property @{
        StandardDeviation = $sd
        Mean = $avg.Average
    }
}

# $Vectors is 2d array. Assumes all elements have same # of elements (rectangular array)
function Normalize-Dimensions {
    param (
        [Parameter(Mandatory=$true)]$Vectors
    )
    for ($i = 0; $i -lt $Vectors[0].Count; $i++) { 
        $MeanAndStdDev = Get-StandardDeviation ( $Vectors | ForEach-Object { $PSItem[$i] } )
        $Vectors | ForEach-Object {
            # if not null, adjust so dimension data set has mean of 0 and standard deviation of 1
            if ($PSItem[$i]) {
                $PSItem[$i] = ( $PSItem[$i] - $MeanAndStdDev.Mean ) / $MeanAndStdDev.StandardDeviation
            }
        }
    }
    Write-Output @(,$Vectors)
}

# Load Accord.MachineLearning dll
$MlDllPath = "$AccordPath\Accord.MachineLearning.dll"
Add-Type -Path $MlDllPath

$Json = Get-Content -Encoding UTF8 C:\temp\kmeanstest.json |
    ConvertFrom-Json

# $Json | select id, @{ Name = "body"; Expression = { $PSItem.data.body } }

#$Vectors = $Json | ForEach-Object { @(,(Featurize-String $PSItem.data.body)) }
#$Vectors = Get-TfIdf ($Json | ForEach-Object { $PSItem.data.body })
$Vectors = Get-TfIdf ($Json | ForEach-Object { $PSItem.data.link_title })
$NormalVectors = Normalize-Dimensions $Vectors

$KMeans = New-Object Accord.MachineLearning.KMeans -ArgumentList $Clusters

# This throws an error, but I think it's erroring out on converting data to output to Powershell; I think the functionality is working
$KMeans.Learn($NormalVectors)

$Labels = $KMeans.Clusters.Decide($Vectors)

$Out = [System.Collections.ArrayList]@()
for ($i = 0; $i -lt $Vectors.Count; $i++) { 
    $Out.Add((
        New-Object psobject -Property @{
            Cluster = $Labels[$i]
            #Text = $Json[$i].data.body
            Text = $Json[$i].data.link_title
        }
    )) | Out-Null
}

# for ($i = 0; $i -lt $Clusters; $i++) { 
#     "`n=== CLUSTER $i ===`n"
#     $Out |
#         Where-Object { $PSItem.Cluster -eq $i } |
#         Select-Object -ExpandProperty Text
# }

$Out | Group-Object -Property Cluster | Sort-Object -Descending -Property Count

# NOTE: I've been running this in ISE and exploring the variable values left over from executing in the live runspace in addition to the script output.