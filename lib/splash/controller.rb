def start(options = {})
      runner = options[:runner]
      unless File::exist? "/tmp/#{runner}.pid" then
        return daemonize :description => "LightESB : #{runner} Runner", :pid_file => "/tmp/#{runner}.pid" do
          runner = "LightESB::Runners::#{runner}".constantize.new
          runner.launch
        end
      end
    end

    def stop(options = {})
      runner = options[:runner]
      if File::exist? "/tmp/#{runner}.pid" then
        Process.kill("TERM", `cat /tmp/#{runner}.pid`.to_i)
        FileUtils::rm "/tmp/#{runner}.pid"
        return true
      end
    end
