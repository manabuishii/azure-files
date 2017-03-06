# azure-files
Azure files


## Create Resource group

```
azure group create AZURERESOURCEGROUP18 -l japaneast
```

## leader and follower

```
azure group deployment create -g AZURERESOURCEGROUP6 -n AzureRMSamples2 --template-uri https://raw.githubusercontent.com/manabuishii/azure-files/master/leader_followers/azuredeploy.json -e /work2/leader_followers/local.parameters.json -v
```

## Ubuntu datadisk1 and datadisk2

```
azure group deployment create -g AZURERESOURCEGROUP6 -n AzurfeRMSamples2 -f /work/diskraid-ubuntu-vm/azuredeploy.json -e /work/diskraid-ubuntu-vm/local.parameters.json -v
```

# test 1

2 of 1023G disks takes `4 min`

# test 2

10 of 1023G disks take `4 min`

```
real	4m5.984s
user	0m2.676s
sys	0m0.320s
```

# 1 machine many disks

```
time azure group deployment create -g AZURERESOURCEGROUP18 -n AzurfeRMSamples11 -f /work2/diskraid-ubuntu-custom-vm/azuredeploy.json -e /work2/diskraid-ubuntu-custom-vm/local.parameters.json -v
```

# 1 machine just ssh vm for mount many disk machine

```
time azure group deployment create -g AZURERESOURCEGROUP18 -n AzurfeRMSamples11 -f /work2/vm-sshkey-script/noaccount.json -e /work2/vm-sshkey-script/local.parameters.json -v
```