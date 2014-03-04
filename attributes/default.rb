#
# Cookbook Name:: cloud
# Attributes:: default
#
# Copyright 2014, AT&T Services, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#
# Name of vault/data bag item with deployment credentials
# Here's a sample of returned data:
#
#  {
#     "cloud": {
#       "openstack_auth_url": "http://openstack_api_endpoint.com/v2.0/tokens",
#       "openstack_tenant": "MyTenent",
#       "openstack_username": "MyUsername",
#       "openstack_api_key": "MyPassw0rd"
#     },
#     "bootstrap": {
#       "client_key": "---BEGIN.....END---",
#       "ssh_key": "---BEGIN.....END---",
#       "validation_key": "---BEGIN.....END---"
#     }
#  }
#

default['cloud']['deploy_data'] = node.chef_environment

default['cloud']['bootstrap'].tap do |bootstrap|
  bootstrap['client_name']       = Chef::Config[:node_name]
  bootstrap['client_key']        = Chef::Config[:client_key]
  bootstrap['validator_path']    = Chef::Config[:validation_key]
  bootstrap['validator_client']  = Chef::Config[:validation_client_name]
  bootstrap['bootstrap_proxy']   = nil
  bootstrap['template']          = nil
  bootstrap['ssh']['keys']       = '/root/deploy.pem'
  bootstrap['ssh']['user']       = 'root'
  bootstrap['chef_version']      = Chef::VERSION
end

default['cloud']['knife'].tap do |knife|
  knife['client_key']             = Chef::Config[:client_key]
  knife['bootstrap_proxy']    = nil
  knife['bootstrap_version']  = Chef::VERSION
  knife['distro'] = nil
  knife['template_file'] = nil
  knife['identity_file'] = '/root/deploy.pem'
  knife['host_key_verify'] = nil
  knife['ssh_gateway'] =nil
  knife['ssh_password'] = nil
  knife['ssh_port'] = nil
  knife['ssh_user'] = 'root'
end
