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

default['cloud']['bootstrap'].tap do |bootstrap|
  bootstrap['client_name']       = Chef::Config[:node_name]
  bootstrap['client_key']        = Chef::Config[:encrypted_data_bag_secret]
  bootstrap['validator_path']    = Chef::Config[:validation_key]
  bootstrap['validator_client']  = Chef::Config[:validation_client_name]
  bootstrap['bootstrap_proxy']   = nil
  bootstrap['template']          = nil
  bootstrap['ssh']['keys']       = nil
  bootstrap['ssh']['user']       = nil
  bootstrap['chef_version']      = nil
end
