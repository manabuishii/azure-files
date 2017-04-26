#
# Cookbook Name:: vmcontrolsetup
# Recipe:: default
#
# Copyright 2017, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
cron 'cookbooks_report' do
  action :create
  minute '*/3'
  user 'azureuser'
  home '/usr/local/periodicscript'
  command %W{
    cd /usr/local/periodicscript && /usr/local/periodicscript/machine_up_down.sh
  }.join(' ')
end