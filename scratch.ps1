$AccordPath = "C:\tools\Accord.NET-3.3.0-libsonly\Release\net45"
$MlDllPath = "$AccordPath\Accord.MachineLearning.dll"
Add-Type -Path $MlDllPath

$KMeans = New-Object Accord.MachineLearning.KMeans -ArgumentList 3