#
# Cookbook Name:: cloud
# Recipes:: setup_credentials
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

if node['local_mode']
  deploy_data = node['cloud']['deploy_data']
else
  include_recipe 'chef-vault'
  deploy_data = chef_vault_item(:cloud, node['cloud']['deploy_data'])
end

template "#{ENV['HOME']}/.fog" do
  variables(
    :data => deploy_data['cloud']
  )
end

file node['cloud']['bootstrap']['ssh']['keys'] do
  content deploy_data['bootstrap']['ssh_key']
  mode '0600'
end
