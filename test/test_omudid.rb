require 'rubygems'

require 'omudid'

module Commander
  module UI
    attr :password
  end
end

require 'terminal-table'
require 'term/ansicolor'

require 'cupertino_compatibility'

require 'test/unit'
require 'vcr'
require 'omudid/portal_agent'

VCR.configure do |c|
  c.cassette_library_dir = 'test/vcr'
  c.hook_into :fakeweb
  c.default_cassette_options = { :serialize_with => :syck }
end

class OneMoreUDIDTest < Test::Unit::TestCase
  def test_teams
    VCR.use_cassette('teams') do
      agent = OneMoreUDID::PortalAgent.new
      agent.login('tech.lawson@gmail.com', 'M4?Sh$92ap')
      teams = agent.get_teams()

      assert teams.count == 2
      assert teams['YRZAGJ6X9R'] == 'David Lawson - iOS Developer Program'
      assert teams['MJF74KN5FM'] == 'Actionpact Limited'
    end
  end

  def test_profiles
    VCR.use_cassette('profiles') do
      agent = OneMoreUDID::PortalAgent.new
      agent.login('tech.lawson@gmail.com', 'M4?Sh$92ap')

      agent.setup_cupertino('YRZAGJ6X9R')
      profiles = agent.list_profiles()

      assert profiles.count == 3
      assert profiles[0].name == 'demo1'
      assert profiles[1].name == 'demo3appstore'
      assert profiles[2].name == 'demo2'
    end
  end

  def test_add
    VCR.use_cassette('add') do
      agent = OneMoreUDID::PortalAgent.new
      agent.login('tech.lawson@gmail.com', 'M4?Sh$92ap')

      agent.setup_cupertino('YRZAGJ6X9R')
      agent.add_device('device_name', 'udid')
      agent.update_profile('demo1')
      #agent.download_new_profile('demo1') not included as requires local file manipulation
    end
  end
end