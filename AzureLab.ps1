Import-Module AzureRM
$Location="ukwest"
$ResourceGroup="CTXSite"

Login-AzureRmAccount
Select-AzureRmSubscription -SubscriptionName "Visual Studio Premium with MSDN"

##New Azure Resource
New-AzureRmResourceGroup -Name $ResourceGroup -Location $Location

##Create new storage accounts
##One for instrastructure and one for workers
New-AzureRmStorageAccount -ResourceGroupName $ResourceGroup -StorageAccountName "ctxinfrastorage" -Location $Location -Type Standard_LRS
New-AzureRmStorageAccount -ResourceGroupName $ResourceGroup -StorageAccountName "ctxworkerstorage" -Location $Location -Type Premium_LRS

$infrastorage=Get-AzureRmStorageAccount -ResourceGroupName $ResourceGroup -Name "ctxinfrastorage"
$workerstorage=Get-AzureRmStorageAccount -ResourceGroupName $ResourceGroup -Name "ctxworkerstorage"

##Upload automation scripts into the storage
##Creating context
$Keys = Get-AzureRmStorageAccountKey -ResourceGroupName $ResourceGroup -Name "ctxinfrastorage"
$StorageContext = New-AzureStorageContext -StorageAccountName "ctxinfrastorage" -StorageAccountKey $Keys[0].Value

##Create automation container
New-AzureStorageContainer -Context $StorageContext -Name "automation"

$adAutomation="C:\Users\EdgarPC\OneDrive\Documents\Scripting\adAutomation.ps1"
$citrixAutomation="C:\Users\EdgarPC\OneDrive\Documents\Scripting\citrixAutomation.ps1"

##Upload the files
$adAutomation=Set-AzureStorageBlobContent -Context $StorageContext -Container "automation" -File $adAutomation
$citrixAutomation=Set-AzureStorageBlobContent -Context $StorageContext -Container "automation" -File $citrixAutomation

##VM build out##
##Local account credentials
$Credential = Get-Credential

########
##DC01##
########
##Network Interface
$SubnetConfig = Get-AzureRmVirtualNetworkSubnetConfig -Name $FrontEndSubnetName -VirtualNetwork $VNetwork
$Interface = New-AzureRmNetworkInterface -Name "DC01_NIC" -ResourceGroupName $ResourceGroup -Location $Location -SubnetId $VNetwork.Subnets[0].Id


##VM Object
$OSDiskName="DC01" + "OSDisk"
$VirtualMachineDC = New-AzureRmVMConfig -VMName "DC01" -VMSize "Standard_DS1_v2"
$VirtualMachineDC = Set-AzureRmVMOperatingSystem -VM $VirtualMachineDC -Windows -ComputerName "DC01" -Credential $Credential -ProvisionVMAgent -EnableAutoUpdate
$VirtualMachineDC = Set-AzureRmVMSourceImage -VM $VirtualMachineDC -PublisherName MicrosoftWindowsServer -Offer WindowsServer -Skus 2016-Datacenter -Version "latest"
$VirtualMachineDC = Add-AzureRmVMNetworkInterface -VM $VirtualMachineDC -Id $Interface.Id
$OSDiskUri = $infrastorage.PrimaryEndpoints.Blob.ToString() + "vhds/" + $OSDiskName + ".vhd"
$VirtualMachineDC = Set-AzureRmVMOSDisk -VM $VirtualMachineDC -Name $OSDiskName -VhdUri $OSDiskUri -CreateOption FromImage
New-AzureRmVM -ResourceGroupName $ResourceGroup -Location $Location -VM $VirtualMachineDC

#########
##DDC01##
#########
##Network Interface
$SubnetConfig = Get-AzureRmVirtualNetworkSubnetConfig -Name $FrontEndSubnetName -VirtualNetwork $VNetwork
$Interface = New-AzureRmNetworkInterface -Name "DDC01_NIC" -ResourceGroupName $ResourceGroup -Location $Location -SubnetId $VNetwork.Subnets[0].Id


##VM Object
$OSDiskName="DDC01" + "OSDisk"
$VirtualMachineDC = New-AzureRmVMConfig -VMName "DDC01" -VMSize "Standard_DS1_v2"
$VirtualMachineDC = Set-AzureRmVMOperatingSystem -VM $VirtualMachineDC -Windows -ComputerName "DDC01" -Credential $Credential -ProvisionVMAgent -EnableAutoUpdate
$VirtualMachineDC = Set-AzureRmVMSourceImage -VM $VirtualMachineDC -PublisherName MicrosoftWindowsServer -Offer WindowsServer -Skus 2016-Datacenter  -Version "latest"
$VirtualMachineDC = Add-AzureRmVMNetworkInterface -VM $VirtualMachineDC -Id $Interface.Id
$OSDiskUri = $infrastorage.PrimaryEndpoints.Blob.ToString() + "vhds/" + $OSDiskName + ".vhd"
$VirtualMachineDC = Set-AzureRmVMOSDisk -VM $VirtualMachineDC -Name $OSDiskName -VhdUri $OSDiskUri -CreateOption FromImage
New-AzureRmVM -ResourceGroupName $ResourceGroup -Location $Location -VM $VirtualMachineDC

#########
##WEB01##
#########
##Network Interface
$SubnetConfig = Get-AzureRmVirtualNetworkSubnetConfig -Name $FrontEndSubnetName -VirtualNetwork $VNetwork
$Interface = New-AzureRmNetworkInterface -Name "WEB01_NIC" -ResourceGroupName $ResourceGroup -Location $Location -SubnetId $VNetwork.Subnets[0].Id


##VM Object
$OSDiskName="WEB01" + "OSDisk"
$VirtualMachineDC = New-AzureRmVMConfig -VMName "WEB01" -VMSize "Standard_DS1_v2"
$VirtualMachineDC = Set-AzureRmVMOperatingSystem -VM $VirtualMachineDC -Windows -ComputerName "WEB01" -Credential $Credential -ProvisionVMAgent -EnableAutoUpdate
$VirtualMachineDC = Set-AzureRmVMSourceImage -VM $VirtualMachineDC -PublisherName MicrosoftWindowsServer -Offer WindowsServer -Skus 2016-Datacenter  -Version "latest"
$VirtualMachineDC = Add-AzureRmVMNetworkInterface -VM $VirtualMachineDC -Id $Interface.Id
$OSDiskUri = $infrastorage.PrimaryEndpoints.Blob.ToString() + "vhds/" + $OSDiskName + ".vhd"
$VirtualMachineDC = Set-AzureRmVMOSDisk -VM $VirtualMachineDC -Name $OSDiskName -VhdUri $OSDiskUri -CreateOption FromImage
New-AzureRmVM -ResourceGroupName $ResourceGroup -Location $Location -VM $VirtualMachineDC

##Run the automation scripts
##Set-up AD

##Set-up Citrix Site