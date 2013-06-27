module OneMoreUDID
  class LocalAgent
    def install_profile(profile_name, filename)

      Dir.glob(File.expand_path('~') + '/Library/MobileDevice/Provisioning Profiles/*.mobileprovision') do |file|

        delete_file = false

        File.open(file, "r") do |_file|

          file_contents = _file.read
          if String.method_defined?(:encode)
            #file_contents.encode!('UTF-8', 'UTF-8', :invalid => :replace)

            file_contents.encode!('UTF-16', 'UTF-8', :invalid => :replace, :replace => '')
            file_contents.encode!('UTF-8', 'UTF-16')
          end
          matches = /<key>Name<\/key>\s+<string>([^<]+)<\/string>/.match file_contents

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

          file_contents = _file.read
          if String.method_defined?(:encode)
            #file_contents.encode!('UTF-8', 'UTF-8', :invalid => :replace)

            file_contents.encode!('UTF-16', 'UTF-8', :invalid => :replace, :replace => '')
            file_contents.encode!('UTF-8', 'UTF-16')
          end

          matches = /<key>Name<\/key>\s+<string>([^<]+)<\/string>/.match file_contents
          profiles << matches[1]
        end

      end

      profiles

    end
  end
end