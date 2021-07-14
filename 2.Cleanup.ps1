$instance = Read-Host "Specify instance"
$instance = $instance.trimend(" ")

$options=New-PSSessionOption -SkipCACheck -SkipCNCheck
Enter-PSSession -ComputerName $instance -Credential Administrator 

$iisWebappName="TestSite"
$physicalPath="C:\Users\Administrator\Documents\Test"
$iisWebsiteName="Default Web Site"


if (Test-Path $physicalPath) {
    Remove-Item $physicalPath -r
}
New-Item $physicalPath
if (Test-Path IIS:\AppPools\$iisWebappName) {
    Remove-WebAppPool -Name $iisWebappName
}
New-WebAppPool -Name $iisWebappName

# See if a website with this name already exists
if (!(Get-Website -Name $iisWebsiteName)){
    Remove-Website -Name $iisWebsiteName
 
#Create a new Website
New-WebSite -Name $iisWebsiteName
            -Port 80 
            -IPAddress * 
            -HostHeader $websiteUrl
            -PhysicalPath $physicalPath
            -ApplicationPool $iisWebsiteName
Set-ItemProperty "IIS:\Sites\$iisWebsiteName"
            -Name Bindings 
            -value @{protocol="http";bindingInformation="*:80:$websiteUrl"}
}