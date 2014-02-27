#
# Copyright:: Copyright (c) 2014 AT&T Inc.
# License:: Apache License, Version 2.0
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

module Fog
  module Cloud
    # Compute methods
    module Compute
      include Fog::Cloud::Base
      def compute
        begin
          require 'fog'
        rescue LoadError
          Chef::Log.error("Missing gem 'fog'. Use the default fog_cloud recipe to install it first.")
        end

        if @new_resource.connection
          # Fog::Logger = Chef::Log unless Fog::Logger == Chef::Log
          @fog ||= Fog::Compute.new(@new_resource.connection.merge(:provider => @new_resource.cloud))
        else
          Chef::Log.error("Missing connection attribute on #{@new_resource.name}")
        end
      end

      def instance_id
        server = current_instance
        server.id
      end

      def current_instance
        compute.servers.select { |s| s.name == @new_resource.name }.first
      end

      def create_instance(keypair, image, flavor, security_groups)
        Chef::Log.info("Creating new #{@new_resource.cloud} instance with name #{@new_resource.name}")
        server = compute.servers.new(:image_ref => image,
                                     :flavor_ref => flavor_ref(flavor),
                                     :security_groups => security_groups,
                                     :key_name => keypair,
                                     :name => @new_resource.name)
        server.save
        server.wait_for { ready? }
        server
      end

      def destroy_instance
        current_instance.destroy unless current_instance.nil?
      end

      def associate_ips(server_id, ip_addresses)
        server = compute.servers.get(server_id)
        ip_addresses.each do |ip|
          server.associate_address(ip) unless server.addresses.include?(ip)
        end
      end

      private

      def flavor_ref(name)
        ref = compute.flavors.select { |f| f.name == name }.first
        ref.id
      end
    end
  end
end
