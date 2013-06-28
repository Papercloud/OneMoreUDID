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
  c.hook_into :webmock # or :fakeweb
  c.default_cassette_options = { :serialize_with => :syck }
end

class OneMoreUDIDTest < Test::Unit::TestCase
  def test_teams
    VCR.use_cassette('teams') do
      agent = OneMoreUDID::PortalAgent.new
      teams = agent.get_teams('test@email.com', 'password')

      assert teams.count == 2
      assert teams['XYZ1'] == 'Team 1'
      assert teams['XYZ2'] == 'Team 2 - iOS Developer Program'
    end
  end
end