param (
    $AccordPath = "C:\tools\Accord.NET-3.3.0-libsonly\Release\net45"
)

# Load Accord.MachineLearning dll
$MlDllPath = "$AccordPath\Accord.MachineLearning.dll"
Add-Type -Path $MlDllPath

# Starting by adapting C# "How to perform clustering with K-Means" example from http://accord-framework.net/docs/html/T_Accord_MachineLearning_KMeans.htm to Powershell

$KMeans = New-Object Accord.MachineLearning.KMeans -ArgumentList 3

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

# This throws an error but otherwise seems to work.
# I think the error might be in enumerating the output to PS which would leave the actual clustering operations intact.
$KMeans.Learn($Observations)

$New = @(, @( 4, 1, 9) )

# Example uses Nearest(), but docs say obsolete and use Decide() instead
$KMeans.Clusters.Decide( $New )