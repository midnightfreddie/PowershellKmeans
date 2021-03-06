# After having successfully implemented the example, this file will cluster and display a 2d plot
param (
    $AccordPath = "C:\tools\Accord.NET-3.3.0-libsonly\Release\net45",
    $Clusters = 6,
    $NumPoints = 1200,
    # ScatterPlot.html.template is currently hard-coded expecting a 100x100 plot area
    $PlotSize = 100
)

# Polar Box-Muller adapted from http://www.design.caltech.edu/erik/Misc/Gaussian.html
# Returns two Guassian-distributed random numbers with peak of 0 and standard deviation of 1
function Get-GaussianRandom {
    Do {
        $x1 = (Get-Random -Maximum 2.0) - 1
        $x2 = (Get-Random -Maximum 2.0) - 1
        $w = $x1 * $x1 + $x2 * $x2
    } While ($w -ge 1.0)
    $w = [Math]::Sqrt( (-2.0 * [Math]::Log($w)) / $w )
    Write-Output ($x1 * $w)
    Write-Output ($x2 * $w)
}

# Being lazy and using parent scope
function Get-RandomPoints {
        1..$NumPoints | ForEach-Object { @(,@((Get-Random -Maximum $PlotSize),(Get-Random  -Maximum $PlotSize) ) ) }
}

# Being lazy and using parent scope
function Get-ClusteredPoints {
    $Radius = $PlotSize / 6
    $Centers = 1..$Clusters | ForEach-Object { @(,@((Get-Random -Maximum $PlotSize),(Get-Random  -Maximum $PlotSize) ) ) }
    $i = 0
    1..$NumPoints | ForEach-Object {
        $r = Get-Random -Maximum $Radius
        $theta = Get-Random  -Maximum 360
        $x = [Math]::Floor($Centers[$i % $Clusters][0] + $r * [Math]::Cos($theta))
        $y = [Math]::Floor($Centers[$i % $Clusters][1] + $r * [Math]::Sin($theta))
        @(,@($x,$y))
        $i++
    }
}

# Being lazy and using parent scope
# An attempt at Gaussian/Normal-distributed points around cluster centers
function Get-GaussianClusteredPoints {
    $RadiusStdDev = $PlotSize / 8
    $Centers = 1..$Clusters | ForEach-Object { @(,@((Get-Random -Maximum $PlotSize),(Get-Random  -Maximum $PlotSize) ) ) }
    $Randoms = 1..([Math]::Ceiling($NumPoints / 2.0)) | ForEach-Object { Get-GaussianRandom }
    $i = 0
    1..$NumPoints | ForEach-Object {
        $r = $Randoms[$i] * $RadiusStdDev
        $theta = Get-Random  -Maximum 360
        $x = $Centers[$i % $Clusters][0] + $r * [Math]::Cos($theta)
        $y = $Centers[$i % $Clusters][1] + $r * [Math]::Sin($theta)
        @(,@($x,$y))
        $i++
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

$KMeans = New-Object Accord.MachineLearning.KMeans -ArgumentList $Clusters

#$Points = Get-RandomPoints
#$Points = Get-ClusteredPoints
#$Points = Get-GaussianClusteredPoints
$Points = Normalize-Dimensions (Get-GaussianClusteredPoints)

# This throws an error, but I think it's erroring out on converting data to output to Powershell; I think the functionality is working
$KMeans.Learn($Points)

$Labels = $KMeans.Clusters.Decide($Points)

$Out = [System.Collections.ArrayList]@()
for ($i = 0; $i -lt $Points.Count; $i++) {
    $Out.Add((
        New-Object psobject -Property ([ordered]@{
                x = $Points[$i][0] * 0.2 * $PlotSize + $PlotSize / 2
                y = $Points[$i][1] * 0.2 * $PlotSize + $PlotSize / 2
                cluster = $Labels[$i]
            })
    )) | Out-Null
}

(Get-Content $PSScriptRoot\ScatterPlot.html.template) -replace 'POINTSDATAGOESHERE', ($Out | ConvertTo-Json) |
    Out-File -Encoding utf8 $PSScriptRoot\out.html