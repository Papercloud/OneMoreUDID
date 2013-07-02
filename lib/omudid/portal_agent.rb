require 'keychain'

module OneMoreUDID
  class PortalAgent

    attr_accessor :agent
    attr_accessor :username, :password

    def login(username, password)
      if username != nil and password != nil
        self.username, self.password = username, password
        return
      end

      accounts = Keychain.generic_password_items.select { |item| item.label == "omudid" }
      username = password = nil
      if accounts and accounts.count > 0
        choice = choose 'Select an account to use:', *accounts.collect{ |account| account.account }.push('New account').push('Delete account')
        case choice
          when "New account"
            puts
          when "Delete account"
            puts
            to_delete = choose 'Select an account to delete:', *accounts.collect{ |account| account.account }.push('ALL')
            case to_delete
              when "ALL"
                accounts.each{ |account| account.delete }
              else
                account = Keychain.generic_password_items.find { |item| item.label == "omudid" and item.account == to_delete }.delete
            end
            abort
          else
            account = Keychain.generic_password_items.find { |item| item.label == "omudid" and item.account == choice }
            username = account.account
            password = account.password
        end
      end
      if username == nil
        username = ask 'Apple Username:'
        password = pw 'Apple Password:'
        puts
        if agree 'Do you want to save these login details? (yes/no)'
          Keychain.add_generic_password('omudid', username, password) rescue say_error 'Credentials not saved, email already stored in keychain.'
        end
      end

      self.username, self.password = username, password
      return username, password
    end

    def get_teams
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

      agent.username = self.username
      agent.password = self.password

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

    def setup_cupertino(team_name = '')
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

      agent.username = self.username
      agent.password = self.password
      agent.instance_variable_set(:@teamName, team_name)

      @agent = agent

      self
    end

    def add_device(device_name, udid)
      device = Device.new
      device.name = device_name
      device.udid = udid

      try {@agent.add_devices(*[device])}
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