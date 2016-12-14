An early attempt at using Accord Framework .NET machine learning library in Powershell.

I was able to download the library only and load it with `Add-Type`. I adapted the
example K-Means code, and it's mostly working, but the example methods are marked as
obsolete, and I'm getting an out-of-index error on `.Nearest()` and `.Decide()`.

I'll come back to this later as I'd like to get it working and run some K-Means
analysis on a few collections of test data.