require 'keychain'

module OneMoreUDID
  class TestFlightAgent < ::Mechanize

    attr_accessor :username, :password

    def login(username, password)
      if username != nil and password != nil
        self.username, self.password = username, password
        return
      end

      accounts = Keychain.generic_password_items.select { |item| item.label == "testflight" }
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
                account = Keychain.generic_password_items.find { |item| item.label == "testflight" and item.account == to_delete }.delete
            end
            abort
          else
            account = Keychain.generic_password_items.find { |item| item.label == "testflight" and item.account == choice }
            username = account.account
            password = account.password
            puts
        end
      end
      if username == nil
        username = ask 'Testflight Username:'
        password = pw 'Testflight Password:'
        puts
        if agree 'Do you want to save these login details? (yes/no)'
          Keychain.add_generic_password('testflight', username, password) rescue say_error 'Credentials not saved, email already stored in keychain.'
        end
        puts
      end

      self.username, self.password = username, password
      return username, password
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

      say_ok 'Submitted '+profile_file.path+"\n"+'Share link: '+page.link_with(:dom_class => 'bitly').text
    end

    def get_profile_file(profile_name)
      Dir.glob(::File.expand_path('~') + '/Library/MobileDevice/Provisioning Profiles/*.mobileprovision') do |file|

        ::File.open(file, "r") do |_file|
          file_contents = _file.read
          if String.method_defined?(:encode)
            #file_contents.encode!('UTF-8', 'UTF-8', :invalid => :replace)

            file_contents.encode!('UTF-16', 'UTF-8', :invalid => :replace, :replace => '')
            file_contents.encode!('UTF-8', 'UTF-16')
          end
          matches = /<key>Name<\/key>\s+<string>([^<]+)<\/string>/.match file_contents
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