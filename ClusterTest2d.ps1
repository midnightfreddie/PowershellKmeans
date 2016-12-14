# After having successfully implemented the example, this file will cluster and display a 2d plot
param (
    $AccordPath = "C:\tools\Accord.NET-3.3.0-libsonly\Release\net45",
    $Clusters = 3,
    $NumPoints = 100,
    $PlotSize = 100
)

# Load Accord.MachineLearning dll
$MlDllPath = "$AccordPath\Accord.MachineLearning.dll"
Add-Type -Path $MlDllPath

$KMeans = New-Object Accord.MachineLearning.KMeans -ArgumentList $Clusters

$Points = 1..$NumPoints | ForEach-Object { @(,@((Get-Random -Maximum $PlotSize),(Get-Random  -Maximum $PlotSize) ) ) }

$KMeans.Learn($Points)

$Labels = $KMeans.Clusters.Decide($Points)

for ($i = 1; $i -lt $Points.Count; $i++) {
    New-Object psobject -Property ([ordered]@{
        x = $Points[$i][0]
        y = $Points[$i][1]
        cluster = $Labels[$i]
    })
}