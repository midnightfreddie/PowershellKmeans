# scratch2.ps1 will use the "obsolete" methods from the documentation examples
param (
    $AccordPath = "C:\tools\Accord.NET-3.3.0-libsonly\Release\net45"
)

# Load Accord.MachineLearning dll
$MlDllPath = "$AccordPath\Accord.MachineLearning.dll"
Add-Type -Path $MlDllPath

# Starting by adapting C# "How to perform clustering with K-Means" example from http://accord-framework.net/docs/html/T_Accord_MachineLearning_KMeans.htm to Powershell

$KMeans = New-Object Accord.MachineLearning.KMeans -ArgumentList 3

# Casting to [double[][]] as in example not needed and possibly was flattening the array
$Observations = @(
    @(-5, -2, -1),
    @(-5, -5, -6),
    @( 2,  1,  1),
    @( 1,  1,  2),
    @( 1,  2,  2),
    @( 3,  1,  2),
    @(11,  5,  4),
    @(15,  5,  6),
    @(10,  5,  6)
)

[int[]]$Labels = $KMeans.Compute($Observations)

$Labels -join ", "

# Note use of @(,) format to ensure 2d array, or that @(4,1,9) vector is one value to pass
$New = @(,@( 4, 1, 9))

$KMeans.Clusters.Nearest( $New )