
$DNSInfo_Functions = @( Get-ChildItem -Path $PSScriptRoot\*.ps1 -Recurse -ErrorAction SilentlyContinue )

Export-ModuleMember -Function $DNSInfoFunction.BaseName