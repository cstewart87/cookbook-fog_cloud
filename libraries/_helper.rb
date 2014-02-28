#
# Cookbook Name:: cloud
# Library:: helper
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

module Cloud
  # Helper methods for HWRPs
  module Helper
    #
    # Helper method to convert Fog models to hashes
    #
    def convert_to_hash(data)
      ::JSON.parse(data.to_json)
    end

    #
    # Helper method to pull bootstrap configs
    #
    def bootstrap_config(key)
      key = key.to_sym
      Chef::Config[:knife][key]
    end

    #
    # Helper method to symbolize hash keys
    #
    def symbolize_hash(hash)
      Hash[hash.map { |(k, v)| [k.to_sym, v] }]
    end
  end
end
