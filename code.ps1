<##### 리소스 그룹 생성 #####>
New-AzResourceGroup -ResourceGroupName myRG1 -Location EastUS
New-AzResourceGroup -ResourceGroupName myRG2 -Location EastAsia

<##### 서브넷 만들기#####>
#프론트엔드 서브넷1 생성-----------------------------
$frontendSubnet1 = New-AzVirtualNetworkSubnetConfig `
  -Name myFrontendSubnet1 `
  -AddressPrefix 10.0.0.0/24
#백엔드 서브넷1 생성
$backendSubnet1 = New-AzVirtualNetworkSubnetConfig `
  -Name myBackendSubnet1 `
  -AddressPrefix 10.0.1.0/24

#프론트엔드 서브넷2 생성-------------------------------
$frontendSubnet2 = New-AzVirtualNetworkSubnetConfig `
  -Name myFrontendSubnet2 `
  -AddressPrefix 20.0.0.0/24
#백엔드 서브넷2 생성
$backendSubnet2 = New-AzVirtualNetworkSubnetConfig `
  -Name myBackendSubnet2 `
  -AddressPrefix 20.0.1.0/24

<##### 가상 네트워크 만들기 #####>
#가상 네트워크1 생성----------------------------------
$vnet1 = New-AzVirtualNetwork `
  -ResourceGroupName myRG1 `
  -Location EastUS `
  -Name myVNet1 `
  -AddressPrefix 10.0.0.0/16 `
  -Subnet $frontendSubnet1, $backendSubnet1
#가상 네트워크2 생성------------------------------------
$vnet2 = New-AzVirtualNetwork `
  -ResourceGroupName myRG2 `
  -Location EastAsia `
  -Name myVNet2 `
  -AddressPrefix 20.0.0.0/16 `
  -Subnet $frontendSubnet2, $backendSubnet2

<##### 공용 IP 주소 만들기 #####>
#공용 IP 주소1 생성---------------------------------------
$pip1 = New-AzPublicIpAddress `
  -ResourceGroupName myRG1 `
  -Location EastUS `
  -AllocationMethod Static `
  -Name myPubIP1
#공용 IP 주소2 생성--------------------------------------
$pip2 = New-AzPublicIpAddress `
  -ResourceGroupName myRG2 `
  -Location EastAsia `
  -AllocationMethod Static `
  -Name myPubIP2

<##### 프론트엔드 VM 만들기 #####>
#프론트엔드 가상 네트워크 인터페이스1 생성--------------------
$frontendNic1 = New-AzNetworkInterface `
  -ResourceGroupName myRG1 `
  -Location EastUS `
  -Name myFrontend1 `
  -SubnetId $vnet1.Subnets[0].Id `
  -PublicIpAddressId $pip.Id
#VM의 관리자 계정에 필요한 사용자 이름 및 암호 설정
$cred = Get-Credential
#프론트엔드 VM1 생성
New-AzVM `
   -Credential $cred `
   -Name myFrontend1 `
   -PublicIpAddressName myPubIP1 `
   -ResourceGroupName myRG1 `
   -Location "EastUS" `
   -Size Standard_DS1_v2 `
   -SubnetName myFrontendSubnet1 `
   -VirtualNetworkName myVNet1 `
   -AsJob
Get-Job

#프론트엔드 가상 네트워크 인터페이스2 생성-------------------
$frontendNic2 = New-AzNetworkInterface `
  -ResourceGroupName myRG2 `
  -Location EastAsia `
  -Name myFrontend2 `
  -SubnetId $vnet2.Subnets[0].Id `
  -PublicIpAddressId $pip.Id
#VM의 관리자 계정에 필요한 사용자 이름 및 암호 설정
$cred = Get-Credential
#프론트엔드 VM2 생성
New-AzVM `
   -Credential $cred `
   -Name myFrontend2 `
   -PublicIpAddressName myPubIP2 `
   -ResourceGroupName myRG2 `
   -Location "EastAsia" `
   -Size Standard_DS1_v2 `
   -SubnetName myFrontendSubnet2 `
   -VirtualNetworkName myVNet2 `
   -AsJob
Get-Job

<##### 네트워크 보안 그룹 만들기 #####>
#프론트엔드 서브넷 네트워크 보안 그룹1 인바운드 규칙------------
$nsgFrontendRule1 = New-AzNetworkSecurityRuleConfig `
  -Name myFrontendNSG1 `
  -Protocol Tcp `
  -Direction Inbound `
  -Priority 200 `
  -SourceAddressPrefix * `
  -SourcePortRange * `
  -DestinationAddressPrefix * `
  -DestinationPortRange 80 `
  -Access Allow
#프론트엔드 네트워크 보안 그룹1 추가
$nsgFrontend1 = New-AzNetworkSecurityGroup `
  -ResourceGroupName myRG1 `
  -Location EastUS `
  -Name myFrontendNSG1 `
  -SecurityRules $nsgFrontendRule

#프론트엔드 서브넷 네트워크 보안 그룹2 인바운드 규칙
$nsgFrontendRule2 = New-AzNetworkSecurityRuleConfig `
  -Name myFrontendNSG2 `
  -Protocol Tcp `
  -Direction Inbound `
  -Priority 200 `
  -SourceAddressPrefix * `
  -SourcePortRange * `
  -DestinationAddressPrefix * `
  -DestinationPortRange 80 `
  -Access Allow
#프론트엔드 네트워크 보안 그룹2 추가
$nsgFrontend2 = New-AzNetworkSecurityGroup `
  -ResourceGroupName myRG2 `
  -Location EastAsia `
  -Name myFrontendNSG2 `
  -SecurityRules $nsgFrontendRule

#백엔드 서브넷 네트워크 보안 그룹1 인바운드 규칙----------------
$nsgBackendRule1 = New-AzNetworkSecurityRuleConfig `
  -Name myBackendNSG1 `
  -Protocol Tcp `
  -Direction Inbound `
  -Priority 100 `
  -SourceAddressPrefix 10.0.0.0/24 `
  -SourcePortRange * `
  -DestinationAddressPrefix * `
  -DestinationPortRange 1433 `
  -Access Allow
#백엔드 네트워크 보안 그룹1 추가
$nsgBackend1 = New-AzNetworkSecurityGroup `
  -ResourceGroupName myRG1 `
  -Location EastUS `
  -Name myBackendNSG1 `
  -SecurityRules $nsgBackendRule

#백엔드 서브넷 네트워크 보안 그룹2 인바운드 규칙-------------------
$nsgBackendRule2 = New-AzNetworkSecurityRuleConfig `
  -Name myBackendNSG2 `
  -Protocol Tcp `
  -Direction Inbound `
  -Priority 100 `
  -SourceAddressPrefix 20.0.0.0/24 `
  -SourcePortRange * `
  -DestinationAddressPrefix * `
  -DestinationPortRange 1433 `
  -Access Allow
#백엔드 네트워크 보안 그룹2 추가
$nsgBacken2d = New-AzNetworkSecurityGroup `
  -ResourceGroupName myRG2 `
  -Location EastAsia `
  -Name myBackendNSG2 `
  -SecurityRules $nsgBackendRule

#가상 네트워크1 가져오기--------------------------------------
$vnet1 = Get-AzVirtualNetwork `
  -ResourceGroupName myRG1 `
  -Name myVNet1

#프론트엔드, 백엔드 서브넷1 가져오기
$frontendSubnet1 = $vnet1.Subnets[0]
$backendSubnet1 = $vnet1.Subnets[1]

#프론트엔드 서브넷1에 네트워크 보안 그룹 추가
$frontendSubnetConfig1 = Set-AzVirtualNetworkSubnetConfig `
  -VirtualNetwork $vnet1 `
  -Name myFrontendSubnet1 `
  -AddressPrefix $frontendSubnet1.AddressPrefix `
  -NetworkSecurityGroup $nsgFrontend1

#백엔드 서브넷1에 네트워크 보안 그룹 추가
$backendSubnetConfig1 = Set-AzVirtualNetworkSubnetConfig `
  -VirtualNetwork $vnet1 `
  -Name myBackendSubnet1 `
  -AddressPrefix $backendSubnet1.AddressPrefix `
  -NetworkSecurityGroup $nsgBackend1

#가상 네트워크에 적용
Set-AzVirtualNetwork -VirtualNetwork $vnet1

#가상 네트워크2 가져오기--------------------------------------
$vnet2 = Get-AzVirtualNetwork `
  -ResourceGroupName myRG2 `
  -Name myVNet2

#프론트엔드, 백엔드 서브넷2 가져오기
$frontendSubnet2 = $vnet2.Subnets[0]
$backendSubnet2 = $vnet2.Subnets[1]

#프론트엔드 서브넷1에 네트워크 보안 그룹 추가
$frontendSubnetConfig2 = Set-AzVirtualNetworkSubnetConfig `
  -VirtualNetwork $vnet2 `
  -Name myFrontendSubnet2 `
  -AddressPrefix $frontendSubnet2.AddressPrefix `
  -NetworkSecurityGroup $nsgFrontend2

#백엔드 서브넷1에 네트워크 보안 그룹 추가
$backendSubnetConfig2 = Set-AzVirtualNetworkSubnetConfig `
  -VirtualNetwork $vnet2 `
  -Name myBackendSubnet2 `
  -AddressPrefix $backendSubnet2.AddressPrefix `
  -NetworkSecurityGroup $nsgBackend2

#가상 네트워크에 적용
Set-AzVirtualNetwork -VirtualNetwork $vnet2

<##### 백엔드 VM 만들기 #####>
#백엔드 가상 네트워크 인터페이스1 생성---------------------------
$backendNic1 = New-AzNetworkInterface `
  -ResourceGroupName myRG1 `
  -Location EastUS `
  -Name myBackend1 `
  -SubnetId $vnet1.Subnets[1].Id

#VM의 관리자 계정에 필요한 사용자 이름 및 암호 설정
$cred = Get-Credential

#백엔드 VM1 생성
New-AzVM `
   -Credential $cred `
   -Name myBackend1 `
   -ImageName "MicrosoftSQLServer:SQL2016SP1-WS2016:Enterprise:latest" `
   -ResourceGroupName myRG1 `
   -Location "EastUS" `
   -SubnetName MyBackendSubnet1 `
   -VirtualNetworkName myVNet1 `
   -Size Standard_DS1_v2 `
   -AsJob
Get-Job

#백엔드 가상 네트워크 인터페이스2 생성---------------------------
$backendNic2 = New-AzNetworkInterface `
  -ResourceGroupName myRG2 `
  -Location EastAsia `
  -Name myBackend2 `
  -SubnetId $vnet2.Subnets[1].Id

#VM의 관리자 계정에 필요한 사용자 이름 및 암호 설정
$cred = Get-Credential

New-AzVM `
   -Credential $cred `
   -Name myBackend2 `
   -ImageName "MicrosoftSQLServer:SQL2016SP1-WS2016:Enterprise:latest" `
   -ResourceGroupName myRG2 `
   -Location "EastAsia" `
   -SubnetName MyBackendSubnet2 `
   -VirtualNetworkName myVNet2 `
   -Size Standard_DS1_v2 `
   -AsJob
Get-Job

<##### 사용자 지정 스크립트 확장을 사용하여 IIS 설치 #####>
Set-AzVMExtension `
  -ResourceGroupName "myRG1" `
  -ExtensionName "IIS" `
  -VMName myFrontend1 `
  -Publisher Microsoft.Compute `
  -ExtensionType CustomScriptExtension `
  -TypeHandlerVersion 1.8 `
  -SettingString '{"commandToExecute":"powershell Add-WindowsFeature Web-Server; powershell Add-Content -Path \"C:\\inetpub\\wwwroot\\Default.htm\" -Value $($env:computername)"}' `
  -Location EastUS

Set-AzVMExtension `
  -ResourceGroupName "myRG2" `
  -ExtensionName "IIS" `
  -VMName myFrontend2 `
  -Publisher Microsoft.Compute `
  -ExtensionType CustomScriptExtension `
  -TypeHandlerVersion 1.8 `
  -SettingString '{"commandToExecute":"powershell Add-WindowsFeature Web-Server; powershell Add-Content -Path \"C:\\inetpub\\wwwroot\\Default.htm\" -Value $($env:computername)"}' `
  -Location EastAsia


#Pub2 분리
$nic = Get-AzNetworkInterface -Name myFrontend2 -ResourceGroup myRG2
$nic.IpConfigurations.publicipaddress.id = $null
Set-AzNetworkInterface -NetworkInterface $nic

#Pub2 삭제
Remove-AzPublicIpAddress `
  -Name myPubIP2 `
	-ResourceGroupName myRG2

<##### 피어링 #####> 
#가상 네트워크 가져오기
$VNet1 = Get-AzVirtualNetwork `
  -ResourceGroupName myRG1 `
  -Name myVNet1
$VNet2 = Get-AzVirtualNetwork `
  -ResourceGroupName myRG2 `
  -Name myVNet2

#피어링
Add-AzVirtualNetworkPeering `
  -Name 'LinkVnet1ToVnet2' `
  -VirtualNetwork $VNet1 `
  -RemoteVirtualNetworkId $VNet2.Id
Add-AzVirtualNetworkPeering `
  -Name 'LinkVnet2ToVnet1' `
  -VirtualNetwork $VNet2 `
  -RemoteVirtualNetworkId $VNet1.Id

#연결 확인
Get-AzVirtualNetworkPeering `
  -ResourceGroupName myRG1 `
  -VirtualNetworkName myVNet1 `
  | Select PeeringState

  Get-AzVirtualNetworkPeering `
  -ResourceGroupName myRG2 `
  -VirtualNetworkName myVNet2 `
  | Select PeeringState


#VM 접속해서 Powershell을 사용하여 ping할 수 있도록 방화벽을 통해 ICMP 사용 설정
#New-NetFirewallRule –DisplayName "Allow ICMPv4-In" –Protocol ICMPv4
#다른 VM프로 원격 접속
#mstsc /v:20.0.0.4
#ping 10.0.0.4

<##### 배스천 생성 #####>
$subnetName = "AzureBastionSubnet"

#가상 네트워크 가져오기
$vnet = Get-AzVirtualNetwork `
  -ResourceGroupName myRG1 `
  -Name myVNet1

#가상 네트워크에 배스천 서브넷 추가
Add-AzVirtualNetworkSubnetConfig `
  -Name $subnetName `
  -AddressPrefix 10.0.2.0/24 `
	-VirtualNetwork $vnet

Set-AzVirtualNetwork -VirtualNetwork $vnet

#공용 주소 생성
$publicip = New-AzPublicIpAddress `
  -ResourceGroupName "myRG1" `
  -name "myPubIP2" `
  -location "East US" `
  -AllocationMethod Static `
  -Sku Standard

#배스천 생성
$bastion = New-AzBastion `
  -ResourceGroupName "myRG1" `
  -Name "myBastion" `
  -PublicIpAddress $publicip `
  -VirtualNetwork $vnet

<##### NAT 게이트웨이 생성 #####>
#NAT 게이트웨이를 위한 공용 주소 생성
$publicIP = New-AzPublicIpAddress `
  -Name 'myPubIP3' `
  -ResourceGroupName 'myRG2' `
  -Location 'EastAsia' `
  -Sku 'Standard' `
  -AllocationMethod 'Static'

#NAT 게이트웨이 생성
$natGateway = New-AzNatGateway `
  -ResourceGroupName 'myRG2' `
  -Name 'myNATGW' `
  -IdleTimeoutInMinutes '10' `
  -Sku 'Standard' `
  -Location 'EastAsia' `
  -PublicIpAddress $publicIP

<##### 모든 리소스 제거
Remove-AzResourceGroup -Name myRG1
Remove-AzRecoveryGroup -Name myRG2
 #####>