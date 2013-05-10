module OneMoreUDID
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
        formatted_teams[team.value] += ' - ' + labels[1].text.strip if labels[1].text.strip != ''
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
            formatted_teams[team.value] += ' - ' + labels[1].text.strip if labels[1].text.strip != ''
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
end