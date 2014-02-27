#
# Cookbook Name:: fog_cloud
# Attributes:: default
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


action :create do
  id = find_instance_id(new_resource.connection[:provider])
  #check if the founded instance id is correct

  unless id == nil
    Chef::Log.info "Instance id #{id}"
    volu = volume_connection(new_resource.connection)
    comp = compute_connection(new_resource.connection)

    v = volu.create_volume(new_resource.name, new_resource.name, new_resource.size.to_s)
    vol_id = v.body['volume']['id']
    v = volu.volumes.find {|v| v.id == vol_id }

    Chef::Log.info "Volume ID #{vol_id}"
    until v.status == "available" do
        Chef::Log.info"Volume status #{v.status}"
        v.reload
    end

    comp.attach_volume(vol_id,id, '')
    until v.status == 'in-use' do
      sleep 1
      v.reload
    end

  end
end

action :destroy do
  id = find_instance_id(new_resource.connection[:provider])
  Chef::Log.info "Instance id: #{id}"
  unless id == nil
    comp = compute_connection(new_resource.connection)
    volu = volume_connection(new_resource.connection)

    volumes = volu.volumes.find_all { |v|
      v.attachments.find { |a|
        a['server_id'] == id
      } != nil and v.display_name == new_resource.name
    }
    Chef::Log.info "We have #{volumes.length} volumes to destroy"
    volumes.each { |v|
      Chef::Log.info "Detaching volume #{v.id}"
      comp.detach_volume(id, v.id)
      until v.status == 'available' do
          sleep 1
          v.reload
      end
      Chef::Log.info "Destroying volume #{v.id}"
        v.destroy
    }
    end
end


def compute_connection(connection)
    @compute_connection ||= Fog::Compute.new(connection)
end

def volume_connection(connection)
    @volume_connection ||= Fog::Volume.new(connection)
end

def find_instance_id(provider)
    # for right now this supports only openstack
    # TODO: add the rest of the providers
    Chef::Log.info "==== PROVIDER #{provider}"
    case provider.to_s.downcase
    when /openstack|rackspace/
      JSON.parse(open('http://169.254.169.254/openstack/latest/meta_data.json').read)["uuid"]
    else
      nil
    end
end
