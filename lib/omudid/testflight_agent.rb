module OneMoreUDID
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