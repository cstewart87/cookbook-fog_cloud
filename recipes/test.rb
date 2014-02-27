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

fog_cloud_compute 'chef_test' do
  action :create
  image '72df9ffd-0a4e-46c7-9280-6f87ab302b98'
  flavor 'm1.small.ssd'
  security_groups %w{ default PingAndSSHDev }
  keypair 'cstewart'
  connection(
    :openstack_auth_url => node[:openstack_auth_url],
    :openstack_username => node[:openstack_username],
    :openstack_api_key => node[:openstack_api_key],
    :openstack_tenant => node[:openstack_tenant]
  )
end

fog_cloud_compute 'chef_test' do
  action :destroy
  connection(
    :openstack_auth_url => node[:openstack_auth_url],
    :openstack_username => node[:openstack_username],
    :openstack_api_key => node[:openstack_api_key],
    :openstack_tenant => node[:openstack_tenant]
  )
end
