#
# Cookbook Name:: fog_cloud
# Recipe:: test
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

cloud_server 'chef_test' do
  action [:create, :bootstrap]
  image '920c7654-50ec-4a76-98d1-288c554a7ec3'
  flavor 'm1.small'
  security_groups %w{ ping-and-ssh }
  keypair 'cstewart'
  run_list %w{
    recipe[apt]
  }
end

# cloud_server 'chef_test' do
#   action :destroy
# end
