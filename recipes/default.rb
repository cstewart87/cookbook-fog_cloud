#
# Cookbook Name:: cloud
# Recipe:: default
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

node.set['build-essential']['compiletime'] = true
include_recipe 'build-essential'

if platform_family?('debian')
  %w{ libxml2-dev libxslt-dev libpq-dev }.each do |pkg|
    package pkg do
      action :nothing
    end.run_action(:install)
  end
else
  %w{ libxml2-devel libxslt-devel }.each do |pkg|
    package pkg do
      action :nothing
    end.run_action(:install)
  end
end

chef_gem 'fog'
chef_gem 'ridley'

require 'fog'
require 'ridley'
