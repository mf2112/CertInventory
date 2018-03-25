$staledate = (Get-Date).AddDays(-90)
$computers = Get-ADComputer -Filter {(OperatingSystem -Like "*Server*") -and (Enabled -eq $True) -and (LastLogonDate -ge $staledate) -and (Modified -ge $staledate) -and (PasswordLastSet -ge $staledate) -and (whenChanged -ge $staledate) -and (serviceprincipalname -ne "*MSClusterVirtualServer*")} | Select name -expandproperty name | Where {(Resolve-DNSName $_.name -ea 0) -and (Test-Connection -ComputerName $_.Name -Count 1 -ea 0)} | Sort
$inv = @()
$inv += "Computer" + ";" + "Subject" + ";" + "SAN" + ";" + "Thumbprint" + ";" + "Issuer Name" + ";" + "Valid Until" + ";" + "Days to Expiration"
foreach ($computer in $computers){
Invoke-Command -ComputerName $computer -ScriptBlock {
Set-Location Cert:\LocalMachine\My
$name = $env:computername
$certs = Get-ChildItem
foreach ($cert in $certs){
$today = Get-Date
$daystoexpire = New-TimeSpan -Start $today -End $Cert.NotAfter
If ($daystoexpire.Days -lt 0){$nodaystoexpire = "Expired"}
Else {$nodaystoexpire = $daystoexpire.Days}
$san = $cert.DnsNameList -replace "{,}",""
$entry = $name + ";" + $cert.subject + ";" + $san + ";" + $cert.thumbprint + ";" + $cert.Issuer + ";" + $cert.NotAfter + ";" + $nodaystoexpire
$inv += $entry
}
}
}
#$inv
$inv > "C:\Temp\cert-report-out.csv"
