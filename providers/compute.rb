#
# Cookbook Name:: fog_cloud
# Providers:: compute
#
# Copyright 2014, Florin STAN
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

include Fog::Cloud::Compute

# Support whyrun
def whyrun_supported?
  true
end

action :create do
  if @current_resource.exists
    Chef::Log.debug("There is already an instance with name=#{@new_resource.name}")
    converge_by("update node data with instance id #{current_instance.name}") do
      node.set[@new_resource.provider]['instances'][current_instance.name] = data_attr(current_instance)
      node.save unless Chef::Config[:solo]
    end
  else
    converge_by("create an instance with name=#{@new_resource.name} size=#{@new_resource.flavor} and update the node data with created instance's data") do
      new_instance = create_instance(@new_resource.keypair,
                                     @new_resource.image,
                                     @new_resource.flavor,
                                     @new_resource.security_groups)
      Chef::Log.info "Instance id #{new_instance.id}"
      associate_ips(new_instance.id, @new_resource.ip_addresses) unless @new_resource.ip_addresses.empty?
      node.set[@new_resource.provider]['instances'][@new_resource.name] = data_attr(new_instance)
      node.save unless Chef::Config[:solo]
    end
  end
end

action :destroy do
  if @current_resource.exists
    Chef::Log.info("Destroying instance #{@new_resource.name}")
    destroy_instance
  else
    Chef::Log.info("Instance #{@new_resource.name} not found")
  end
  converge_by("removing #{@new_resource.name} instance from node data") do
    node.set[@new_resource.provider]['instances'][@new_resource.name] = nil
    node.save unless Chef::Config[:solo]
  end
end

def load_current_resource
  @current_resource = Chef::Resource::FogCloudCompute.new(@new_resource.name)
  @current_resource.name(@new_resource.name)
  @current_resource.image(@new_resource.image)
  @current_resource.flavor(@new_resource.flavor)
  @current_resource.security_groups(@new_resource.security_groups)
  @current_resource.ip_addresses(@new_resource.ip_addresses)

  @current_resource.exists = true unless current_instance.nil?
end
