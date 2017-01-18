﻿# EDIT THIS!
# Put your subscription name in a variable.  
# This is really only needed if your credentials are authorized to access multiple subscriptions.  
# If you only have one subscription, a simple "Login-AzureRmAccount" command will suffice.
#
$azureAccount = "KevRem Azure"
# $azureAccount = "Visual Studio Ultimate with MSDN"

# Login
Login-AzureRmAccount
Get-AzureRmSubscription -SubscriptionName $azureAccount | Select-AzureRmSubscription 

# EDIT THIS!
# Set the path to where you've cloned the NTestDSC contents.
# Important: Make sure the path ends with the "\", as in "C:\Code\MyGitHub\NTestDSC\"
$localAssets = "C:\Code\MyGitHub\NTestDSC - Copy\"

# Datacenter Region you want to use.  
# Note that some regions don't yet support Azure Automation. You'll get an error if you pick one of those.
$loc = "East US 2"

# Collect digit(s) for generating unique names
#
$rnd = Read-Host -Prompt "Please type some number for creating unique names, and then press ENTER."

$rgName = 'RG-WebScaleSet' + $rnd
$autoAccountName = 'webAutomation' + $rnd

New-AzureRmResourcegroup -Name $rgName -Location $loc -Verbose

New-AzureRMAutomationAccount -ResourceGroupName $rgName -Name $autoAccountName -Location $loc -Plan Free -Verbose

$RegistrationInfo = Get-AzureRmAutomationRegistrationInfo -ResourceGroupName $rgName -AutomationAccountName $autoAccountName

$NewGUID = [system.guid]::newguid().guid

# This deployment requires pulling remote files, either from Azure Storage (Shared Access Signature) or from a URL like Github.
#
$assetLocation = "https://raw.githubusercontent.com/KevinRemde/VTestDSCSS/master/"

# Setup variables for the local template and parameter files..
#
#$templateFileLoc = $localAssets + "azuredeploy.json"
#$parameterFileLoc = $localAssets + "azuredeploy.parameters.json"

$templateFileLoc = $assetLocation + "azuredeploy.json"
$parameterFileLoc = $assetLocation + "azuredeploy.parameters.json"

$configuration = "WebServer.ps1"
$configurationName = "WebServer"
$nodeConfigurationName = $configurationName + ".localhost"
$configurationURI = $assetLocation + $configuration

$moduleName = "xNetworking"
$moduleURI = $assetLocation + $moduleName + ".zip"

# Get a unique DNS name
#
$machine = "kar"
$uniquename = $false
$counter = 0
while ($uniqueName -eq $false) {
    $dnsPrefix = "$machine" + "dns" + "$rnd" + "$counter" 
    if (Test-AzureRmDnsAvailability -DomainNameLabel $dnsPrefix -Location $loc) {
        $uniquename = $true
    }
    $counter ++
} 

#
# For this deployment I use the github-based template file, parameter file, and additional parameters in the command.
# 
New-AzureRmResourceGroupDeployment -Name TestDeployment -ResourceGroupName $rgName `
    -TemplateParameterUri $parameterFileLoc `
    -TemplateUri $templateFileLoc `
    -domainNamePrefix $dnsPrefix `
    -adminUsername "vAdmin" `
    -automationAccountName $autoAccountName `
    -registrationKey ($RegistrationInfo.PrimaryKey | ConvertTo-SecureString -AsPlainText -Force) `
    -registrationUrl $RegistrationInfo.Endpoint `
    -jobid $NewGUID `
    -nodeConfigurationName $nodeConfigurationName `
    -moduleName $moduleName `
    -moduleURI $moduleURI `
    -configurationName $configurationName `
    -configurationURI $configurationURI `
    -Verbose 

# later if you want, you can easily remove the resource group and all objects it contains.
#
# Remove-AzureRmResourceGroup -Name $rgName -Force