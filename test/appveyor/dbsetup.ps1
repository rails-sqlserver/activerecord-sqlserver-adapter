
Write-Output "Setting up..."
[reflection.assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null
[reflection.assembly]::LoadWithPartialName("Microsoft.SqlServer.SqlWmiManagement") | Out-Null

Write-Output "Setting variables..."
$serverName = $env:COMPUTERNAME
$instances = @('SQL2012SP1', 'SQL2014')
$smo = 'Microsoft.SqlServer.Management.Smo.'
$wmi = new-object ($smo + 'Wmi.ManagedComputer')

Write-Output "Configure Instances..."
foreach ($instance in $instances) {
  Write-Output "Instance $instance ..."
  Write-Output "Enable TCP/IP and port 1433..."
  $uri = "ManagedComputer[@Name='$serverName']/ServerInstance[@Name='$instance']/ServerProtocol[@Name='Tcp']"
  $tcp = $wmi.GetSmoObject($uri)
  $tcp.IsEnabled = $true
  foreach ($ipAddress in $Tcp.IPAddresses) {
    $ipAddress.IPAddressProperties["TcpDynamicPorts"].Value = ""
    $ipAddress.IPAddressProperties["TcpPort"].Value = "1433"
  }
  $tcp.Alter()
}

Set-Service SQLBrowser -StartupType Manual
Start-Service SQLBrowser
