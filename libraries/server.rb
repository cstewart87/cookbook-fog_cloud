#
# Cookbook Name:: cloud
# HWRP:: cloud_server
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

class Chef
  class Resource::CloudServer < Resource
    identity_attr :name

    attr_writer :exists, :running

    def initialize(name, run_contect = nil)
      super

      # Set the resource name and provider
      @resource_name = :cloud_server
      @provider = Provider::CloudServer

      # Set default actions and allowed actions
      @action = :create
      @allowed_actions.push(:create, :destroy, :bootstrap)

      # Set the name attribute and default attributes
      @name = name
      @cloud = 'openstack'
      @security_groups = %w{ default }
      @ip_addresses = []
      @run_list = []
      @fail_on_bootstrap = false

      # State attributes that are set by the provider
      @exists = false
      @running = false
    end

    #
    # The name of the server
    #
    # @param [String] arg
    # @return [String]
    #
    def name(arg = nil)
      set_or_return(:name, arg, kind_of: String)
    end

    #
    # The connection data
    #
    # @param [Hash] arg
    # @return [Hash] arg
    #
    def connection(arg = nil)
      set_or_return(:connection, arg, kind_of: Hash)
    end

    #
    # The name of the keypair to launch with
    #
    # @param [String] arg
    # @return [String]
    #
    def keypair(arg = nil)
      set_or_return(:keypair, arg, kind_of: String)
    end

    #
    # The id of the image to launch
    # 
    # @param [String] arg
    # @return [String] arg
    #
    def image(arg = nil)
      set_or_return(:image, arg, kind_of: String)
    end

    #
    # The flavor of the server
    #
    # @param [String] arg
    # @return [String]
    #
    def flavor(arg = nil)
      set_or_return(:flavor, arg, kind_of: String)
    end

    #
    # The security groups to launch with
    #
    # @param [Array] arg
    # @return [Array] arg
    #
    def security_groups(arg = nil)
      set_or_return(:security_groups, arg, kind_of: Array)
    end

    #
    # The ip addresses to associate
    #
    # @param [Array] arg
    # @return [Array] arg
    #
    def ip_addresses(arg = nil)
      set_or_return(:ip_addresses, arg, kind_of: Array)
    end

    #
    # The cloud provider
    #
    # @param [String] arg
    # @return [String] arg
    #
    def cloud(arg = nil)
      set_or_return(:cloud, arg, kind_of: String)
    end

    #
    # The nodes run list
    #
    # @param [Array] arg
    # @return [Array] arg
    #
    def run_list(arg = nil)
      set_or_return(:run_list, arg, kind_of: Array)
    end

    #
    # Determines if run fails on any bootstrap
    #
    # @param [Boolean] arg
    # @return [Boolean] arg
    #
    def fail_on_bootstrap(arg = nil)
      set_or_return(:fail_on_bootstrap, arg, kind_of: [TrueClass, FalseClass])
    end

    #
    # Determine if the instance already exists.  This value is set by the
    # provider when the current resource is loaded
    #
    # @return [Boolean]
    #
    def exists?
      !!@exists
    end

    #
    # Determine if the instance running.  This value is set by the
    # provider when the current resource is loaded
    #
    # @return [Boolean]
    #
    def running?
      !!@running
    end
  end
end

class Chef
  class Provider::CloudServer < Provider

    require 'chef/mixin/shell_out'
    include Chef::Mixin::ShellOut

    require_relative '_helper'

    include Cloud::Helper

    def load_current_resource
      Chef::Log.debug("Loading current resource #{new_resource}")

      @current_resource = Resource::CloudServer.new(new_resource.name)
      @current_resource.name(new_resource.name)
      @current_resource.image(new_resource.image)
      @current_resource.flavor(new_resource.flavor)
      @current_resource.security_groups(new_resource.security_groups)
      @current_resource.ip_addresses(new_resource.ip_addresses)

      if current_instance
        @current_resource.exists = true
        @current_resource.running = current_instance.ready?
      else
        @current_resource.exists = false
        @current_resource.running = false
      end
    end

    #
    # This provider supports why-run mode.
    #
    def whyrun_supported?
      true
    end

    #
    # Idempotently create a new cloud server with the current resource's name
    # and parameters. If the server already exists, no action will be
    # taken. If the server does not exist, one will be created from the given
    # parameters using the Fog API.
    #
    # Requirements:
    #   - `image` parameter
    #   - `flavor` parameter
    #   - `keypair` parameter
    #   - `security_groups` parameter
    #
    # Optional:
    #   - `addresses` parameter
    #
    def action_create
      validate_image!
      validate_flavor!
      validate_keypair!
      validate_security_groups!
      validate_addresses!

      if current_resource.exists?
        Chef::Log.debug("#{new_resource} exists - skipping")
      else
        converge_by("Create #{new_resource}") do
          server = compute.servers.new(:image_ref => new_resource.image,
                                       :flavor_ref => flavor_ref(new_resource.flavor),
                                       :security_groups => new_resource.security_groups,
                                       :key_name => new_resource.keypair,
                                       :name => new_resource.name)
          server.save
          server.wait_for { ready? }
        end
      end

      if correct_addresses?
        Chef::Log.debug("#{new_resource} associated addresses up to date - skipping")
      else
        new_resource.ip_addresses.each do |addr|
          converge_by("Associating #{addr} to #{new_resource}") do
            current_instance.associate_address(addr)
          end
        end
      end

      converge_by("Update instance info for #{new_resource}") do
        node.set['cloud'][new_resource.cloud]['instances'][new_resource.name] = convert_to_hash(current_instance)
        node.save unless Chef::Config[:solo]
      end
    end

    #
    # Idempotently delete a cloud server with the current resource's name. If
    # the server does not exist, no action will be taken. If the server does exist,
    # it will be deleted using the Fog API.
    #
    def action_destroy
      if current_resource.exists?
        converge_by("Delete #{new_resource} and update attributes") do
          current_instance.destroy
          node.set['cloud'][new_resource.cloud]['instances'][new_resource.name] = nil
          node.save unless Chef::Config[:solo]
          ridley.node.delete(new_resource.name)
          ridley.client.delete(new_resource.name)
        end
      else
        node_obj = ridley.node.find(new_resource.name)
        client_obj = ridley.client.find(new_resource.name)
        if node_obj
          converge_by("Remove left over object node[#{new_resource.name}") do
            ridley.node.delete(new_resource.name)
          end
        end
        if client_obj
          converge_by("Remove left over object client[#{new_resource.name}") do
            ridley.client.delete(new_resource.name)
          end
        end
        unless node_obj || client_obj
          Chef::Log.debug("#{new_resource} does not exist - skipping")
        end
      end
    end

    #
    # Idempotently bootstrap a cloud server with the current resource's name. If
    # the server does not exist, it will be created. If the server does exist,
    # it will be bootstrapped using the Chef API.
    #
    def action_bootstrap
      validate_run_list!

      if current_resource.exists?
          converge_by("Converge #{new_resource}") do
            Chef::Log.debug('Sleeping for 15 seconds before running bootstrap.')
            sleep(15)

            puts "\n\n" # Bootstrap output gets appended to current STDOUT line
            
            bootstrap_cmd = Mixlib::ShellOut.new("knife bootstrap #{current_instance.ip_addresses.last} -N #{new_resource.name} -E #{node.chef_environment} -i #{node['cloud']['bootstrap']['ssh']['keys']} -c /etc/chef/client.rb -r #{new_resource.run_list.join('')}", :live_stream => Chef::Config[:log_location])
            bootstrap_cmd.run_command
            if bootstrap_cmd.exitstatus != 0
              Chef::Log.warn(bootstrap_cmd.stderr)
              fail("#{new_resource} failed to converge!") if new_resource.fail_on_bootstrap
            else
              Chef::Log.debug(bootstrap_cmd.stdout)
            end
          end
      else
        action_create
        action_bootstrap
      end
    end

    private

    #
    # Fog::Compute object for interacting with cloud
    #
    # @return [Fog::Compute]
    #
    def compute
      begin
        require 'fog'
      rescue LoadError
        Chef::Log.error("Missing gem 'fog'. Use the cloud::default recipe to install it first.")
      end

      if new_resource.connection
        # Fog::Logger = Chef::Log unless Fog::Logger == Chef::Log
        @fog ||= Fog::Compute.new(new_resource.connection.merge(:provider => new_resource.cloud))
      elsif ::File.exists?("#{ENV['HOME']}/.fog")
        Fog::Logger[:warning] = Chef::Log
        @fog ||= Fog::Compute.new(:provider => new_resource.cloud)
      else
        Chef::Log.error("Missing ~/.fog config file and connection parameter.  Use cloud::setup_credentials or add credentials to setup.")
      end
    end

    #
    # Ridley::Client object for interacting with Chef
    #
    # @return [Ridley::Client]
    #
    def ridley
      begin
        require 'ridley'
      rescue LoadError
        Chef::Log.error("Missing gem 'ridley'. Use the cloud::default recipe to install it first.")
      end

      connection_options = node['cloud']['bootstrap'].to_hash
      ridley_options = {
        :server_url => Chef::Config[:chef_server_url],
        :client_name => connection_options['client_name'],
        :client_key => connection_options['client_key'],
        :validator_client => connection_options['validator_client'],
        :validator_path => connection_options['validator_path'],
        :ssh => {
          :user => connection_options['ssh']['user'],
          :keys => connection_options['ssh']['keys']
        }
      }
      Chef::Log.debug("Ridley connection options set to:\n#{ridley_options}\n")
      Ridley::Logging.logger.level = Logger.const_get 'ERROR'
      @ridley ||= Ridley.new(ridley_options)
      # @ridley ||= Ridley.new(connection_options.merge(:server_url => Chef::Config[:chef_server_url]))
    end

    # The current instance.
    #
    # @return [nil, Fog::Compute::Server]
    #  nil if the instance does not exist, or a Fog::Compute::Server model if it does
    def current_instance
      return @current_instance if @current_instance

      Chef::Log.debug "Load #{new_resource} instance information"

      @current_instance = compute.servers.select { |s| s.name == new_resource.name }.first
      @current_instance
    end

    #
    # Helper method for determining if any given IP addresses are in sync with the
    # current params for the cloud server.
    #
    # @return [Boolean]
    #
    def correct_addresses?
      new_resource.ip_addresses.each do |addr|
        return false if current_instance.ip_addresses.include?(addr) == false
      end
      true
    end

    def flavor_ref(name)
      ref = compute.flavors.select { |f| f.name == name }.first
      ref.id
    end

    #
    # Validate that an image was given as a parameter to the
    # resource. This method also validates the given image exists
    # on the target cloud.
    #
    def validate_image!
      Chef::Log.debug "Validate #{new_resource} image"

      if new_resource.image.nil?
        fail("#{new_resource} must specify an image!")
      elsif compute.images.get(new_resource.image).nil?
        fail("#{new_resource} image `#{new_resource.image}` does not exist!")
      end
    end

    #
    # Validate that a flavor was given as a parameter to the
    # resource. This method also validates the given flavor exists
    # on the target cloud.
    #
    def validate_flavor!
      Chef::Log.debug "Validate #{new_resource} instance type"

      if new_resource.flavor.nil?
        fail("#{new_resource} must specify a flavor!")
      elsif compute.flavors.select { |f| f.name == new_resource.flavor }.empty?
        fail("#{new_resource} flavor `#{new_resource.flavor}` does not exist!")
      end
    end

    #
    # Validate that a keypair was given as a parameter to the
    # resource. This method also validates the given keypair exists
    # on the target cloud.
    #
    def validate_keypair!
      Chef::Log.debug "Validate #{new_resource} keypair"

      if new_resource.keypair.nil?
        fail("#{new_resource} must specify a keypair!")
      else
        keys_response = compute.list_key_pairs.body['keypairs']
        key = keys_response.select { |k| k['keypair']['name'] == new_resource.keypair }.first
        fail("#{new_resource} keypair `#{new_resource.keypair}` does not exist!") if key.nil?
      end
    end

    #
    # Validate that a security group was given as a parameter to the
    # resource. This method also validates the given security group(s)
    # exist on the target cloud.
    #
    def validate_security_groups!
      Chef::Log.debug "Validate #{new_resource} security groups"

      if new_resource.security_groups.empty?
        fail("#{new_resource} must specify a security group!")
      else
        new_resource.security_groups.each do |group|
          obj = compute.security_groups.select { |g| g.name == group }.first
          fail("#{new_resource} security group `#{group}` does not exist!") if obj.nil?
        end
      end
    end

    #
    # Validate that any give IP addresses given as a parameter to the
    # resource exists on the target cloud and are not currently in use.
    #
    def validate_addresses!
      Chef::Log.debug "Validate #{new_resource} IP addresses"

      if new_resource.ip_addresses.empty?
        Chef::Log.debug("#{new_resource} will not have a public IP.")
      else
        new_resource.ip_addresses.each do |address|
          ip = compute.addresses.select { |addr| addr.ip == address }.first
          if ip.nil?
            fail("#{new_resource} IP address `#{address}` does not exist!")
          elsif ip.instance_id && ip.instance_id != current_instance.id
            fail("#{new_resource} IP address `#{address}` is currently in use!")
          end
        end
      end
    end

    #
    # Validate that a run list was given as a parameter to the
    # resource and that all objects exist on the Chef server.
    #
    def validate_run_list!
      Chef::Log.debug "Validate #{new_resource} run list"

      if new_resource.run_list.empty?
        fail("#{new_resource} must specify a run list when bootstrapping!")
      else
        new_resource.run_list.each do |item|
          if item.match(/(role|recipe)/).nil?
            fail("#{new_resource} run list item `#{item}` must be either role or recipe!")
          elsif item.match(/role/)
            role = item.gsub('role[', '').split(']').first
            fail("#{new_resource} run list item `#{item}` does not exist on Chef server!") if ridley.role.find(role).nil?
          elsif item.match(/recipe/)
            cookbook = item.gsub('recipe[', '').split(']').first.split('::').first
            environment = ridley.environment.find(node.chef_environment)
            if environment && environment.cookbook_versions[cookbook]
              cookbook_version = environment.cookbook_versions[cookbook]
            else
              cookbook_version = 'latest'
            end
            fail("#{new_resource} run list item `#{item}` does not exist on Chef server!") if ridley.cookbook.find(cookbook, cookbook_version).nil?
          end
        end
      end
    end

    def bootstrap_for_node
      bootstrap = Chef::Knife::Bootstrap.new
      bootstrap.name_args = [current_instance.ip_addresses.last]
      bootstrap_config = node['cloud']['bootstrap']
      bootstrap.config[:ssh_user] = bootstrap_config['ssh_user']
      bootstrap.config[:ssh_port] = bootstrap_config['ssh_port']
      bootstrap.config[:identity_file] = bootstrap_config['ssh']['keys']
      bootstrap.config[:host_key_verify] = bootstrap_config['host_key_verify']
      bootstrap.config[:use_sudo] = true unless bootstrap_config['ssh_user'] == 'root'
      bootstrap.config[:chef_node_name] = new_resource.name
      bootstrap.config[:run_list] = new_resource.run_list.join(',')
      bootstrap.config[:prerelease] = bootstrap_config['prerelease']
      bootstrap.config[:bootstrap_version] = Chef::VERSION
      bootstrap.config[:distro] = bootstrap_config['distro']
      bootstrap.config[:template_file] = bootstrap_config['template']
      bootstrap.config[:bootstrap_proxy] = bootstrap_config['bootstrap_proxy']
      bootstrap.config[:environment] = node.chef_environment
      Chef::Config[:knife][:hints] ||= {}
      Chef::Config[:knife][:hints][new_resource.cloud] ||= {}
      bootstrap
    end

  end
end
  