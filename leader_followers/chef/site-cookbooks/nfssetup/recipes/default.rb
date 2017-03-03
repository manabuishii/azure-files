#
# Cookbook Name:: nfssetup
# Recipe:: default
#
# Copyright 2017, YOUR_COMPANY_NAMERIKEN Bioinformatics Research Unit Released
#
# Apache 2.0
#
nfs_export "/datadisks/disk1" do
  network '10.0.0.0/24'
  writeable true 
  sync true
  options ['no_root_squash']
end