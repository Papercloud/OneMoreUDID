require 'mechanize'
require 'spinning_cursor'
require 'rainbow'

module OneMoreUDID
  VERSION = "0.0.1"

  class PortalAgent

    attr_accessor :agent

    def get_teams(username, password)
      agent = Cupertino::ProvisioningPortal::Agent.new

      agent.instance_eval do
        def get(uri, parameters = [], referer = nil, headers = {})
          uri = ::File.join("https://#{Cupertino::HOSTNAME}", uri) unless /^https?/ === uri

          3.times do
            SpinningCursor.start do
              banner 'Loading page...'
              action do
                ::Mechanize.instance_method(:get).bind(self).call(uri, parameters, referer, headers)
              end
              message 'Loading page... '+'done'.color(:green)
            end

            return page unless page.respond_to?(:title)

            case page.title
              when /Sign in with your Apple ID/
                login! and next
              else
                return page
            end
          end

          raise UnsuccessfulAuthenticationError
        end
      end

      agent.username = username
      agent.password = password

      agent.get('https://developer.apple.com/account/selectTeam.action')

      teams = agent.page.form_with(:name => 'saveTeamSelection').radiobuttons

      formatted_teams = {}
      teams.each do |team|
        labels = agent.page.search("label[for=\"#{team.dom_id}\"]")
        formatted_teams[team.value] = labels[0].text.strip
        formatted_teams[team.value] += ' – ' + labels[1].text.strip if labels[1].text.strip != ''
      end

      formatted_teams
    end

    def setup_cupertino(username, password, team_name = '')
      agent = Cupertino::ProvisioningPortal::Agent.new

      agent.instance_eval do
        def get(uri, parameters = [], referer = nil, headers = {})
          uri = ::File.join("https://#{Cupertino::HOSTNAME}", uri) unless /^https?/ === uri

          3.times do
            SpinningCursor.start do
              banner 'Loading page...'
              action do
                ::Mechanize.instance_method(:get).bind(self).call(uri, parameters, referer, headers)
              end
              message 'Loading page... '+'done'.color(:green)
            end

            return page unless page.respond_to?(:title)

            case page.title
              when /Sign in with your Apple ID/
                login! and next
              when /Select Team/
                select_team! and next
              else
                return page
            end
          end

          raise UnsuccessfulAuthenticationError
        end

        def team
          teams = page.form_with(:name => 'saveTeamSelection').radiobuttons

          formatted_teams = {}
          teams.each do |team|
            labels = page.search("label[for=\"#{team.dom_id}\"]")
            formatted_teams[team.value] = labels[0].text.strip
            formatted_teams[team.value] += ' – ' + labels[1].text.strip if labels[1].text.strip != ''
          end

          if formatted_teams[@teamName]
            @team = @teamName
          else
            puts
            say_warning 'Note: you can specify the team with a command-line argument'
            puts
            chosen_team = choose 'Please select one of the following teams:', *formatted_teams.collect { |id, name| id + ': ' + name }
            puts
            regex = /^[^:]*/
            @team = (chosen_team.match regex)[0]
          end

          @team
        end
      end

      agent.username = username
      agent.password = password
      agent.instance_variable_set(:@teamName, team_name)

      @agent = agent

      self
    end

    def add_device(device_name, udid)
      device = Device.new
      device.name = device_name
      device.udid = udid

      try {@agent.add_devices(*[device])}

      say_ok 'Device ' + device.name + ' (' + device.udid + ') added'
    end

    def list_profiles()
      try{@agent.list_profiles(:distribution)}
    end

    def update_profile(profile_name)
      profiles = try{@agent.list_profiles(:distribution)}
      profile = (profiles.select { |profile| profile.name == profile_name }).first

      if !profile
        say_error 'Provisioning profile not found, profiles available:'

        #modularise this?
        table = Terminal::Table.new do |t|
          t << ['Name', 'Type', 'App ID', 'Status']
          t << :separator

          profiles.each do |profile|
            t << [profile.name, profile.type, profile.app_id, profile.status]
          end
        end

        puts table

        abort
      end

      @agent.manage_devices_for_profile(profile) do |on, off|
        #enable all devices
        on + off
      end
    end

    def download_new_profile(profile_name)
      profiles = try{@agent.list_profiles(:distribution)}
      profile = (profiles.select { |profile| profile.name == profile_name }).first

      if !profile
        say_error 'New provisioning profile not found, profiles available:'
        puts profiles
        abort
      end

      filename = ''
      5.times do
        begin
          sleep 5
          if filename = @agent.download_profile(profile)
            say_ok 'Downloaded new profile (' + Dir.pwd + '/' + filename + ')'
            break
          else
            say_error 'Could not download profile'
          end
        rescue
          say_error 'Could not download profile'
        end
      end

      if filename == ''
        abort
      end

      filename
    end
  end

  class LocalAgent
    def install_profile(profile_name, filename)

      Dir.glob(File.expand_path('~') + '/Library/MobileDevice/Provisioning Profiles/*.mobileprovision') do |file|

        delete_file = false

        File.open(file, "r") do |_file|
          matches = /<key>Name<\/key>\s+<string>([^<]+)<\/string>/.match _file.read
          if matches[1] == profile_name
            delete_file = true
          end
        end

        if delete_file
          say_warning 'Old profile deleted ('+ file +')'
          File.delete(file)
          break
        end

      end

      new_path = File.expand_path('~') + '/Library/MobileDevice/Provisioning Profiles/' + filename
      File.rename(Dir.pwd + '/' + filename, new_path)

      say_ok 'New profile installed ('+new_path+')'
    end

    def get_profiles

      profiles = []

      Dir.glob(File.expand_path('~') + '/Library/MobileDevice/Provisioning Profiles/*.mobileprovision') do |file|

        File.open(file, "r") do |_file|
          matches = /<key>Name<\/key>\s+<string>([^<]+)<\/string>/.match _file.read
          profiles << matches[1]
        end

      end

      profiles

    end
  end

  class TestFlightAgent < ::Mechanize

    attr_accessor :username, :password

    def initialize(username, password)
      super()
      @username = username
      @password = password
      self
    end

    def get(uri, parameters = [], referer = nil, headers = {})
      3.times do
        SpinningCursor.start do
          banner 'Loading page...'
          action do
            super(uri, parameters, referer, headers)
          end
          message 'Loading page... '+'done'.color(:green)
        end

        return page unless page.respond_to?(:body)

        case page.body
          when /Login to TestFlight and FlightPath/
            login! and next
          else
            return page
        end
      end

      raise UnsuccessfulAuthenticationError
    end

    def get_apps
      get('https://testflightapp.com/dashboard/applications/')

      apps = page.search('tr.goapp')
      regex = /([0-9]+)/
      apps.collect { |app| [(app['id'].match regex)[1], app.search('h2 small').text.strip] }
    end

    def get_builds(app_id)
      get("https://testflightapp.com/dashboard/applications/#{app_id}/builds/")

      builds = page.search('tr.goversion')
      regex = /([0-9]+)/
      builds.collect { |build| [(build['id'].match regex)[1], build.search('td:first')[0].text] }
    end

    def upload(build_id, profile_name)
      get("https://testflightapp.com/dashboard/builds/update/#{build_id}/")

      profile_file = get_profile_file(profile_name)

      form = page.form_with(:id => 'provision-form')
      upload = form.file_uploads.first
      upload.file_name = profile_file.path
      form.submit

      say_ok 'Submitted '+profile_file.path
    end

    def get_profile_file(profile_name)
      Dir.glob(::File.expand_path('~') + '/Library/MobileDevice/Provisioning Profiles/*.mobileprovision') do |file|

        ::File.open(file, "r") do |_file|
          matches = /<key>Name<\/key>\s+<string>([^<]+)<\/string>/.match _file.read
          if matches[1] == profile_name
            return _file
          end
        end

      end
    end

    private

    def login!
      form = page.forms[0]
      form.username = self.username
      form.password = self.password
      form.submit
    end
  end

end
