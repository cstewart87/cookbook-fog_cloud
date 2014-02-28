require 'chefspec'
require 'chefspec/berkshelf'

describe 'fog_cloud::test' do
  # Use an explicit subject
  let(:chef_run) do
    ChefSpec::Runner.new(:platform => 'ubuntu', :version => '12.04').converge(described_recipe)
  end

  it 'runs examples'
end
