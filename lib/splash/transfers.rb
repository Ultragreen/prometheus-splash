# coding: utf-8

# base Splash Module
module Splash

  # Transfers module
  module Transfers

    include Splash::Config
    include Splash::Loggers
    include Splash::Helpers



    class TxNotifier
      @@registry = Prometheus::Client::Registry::new
      @@metric_nbfiles = Prometheus::Client::Gauge.new(:txnbfiles, docstring: 'SPLASH metric transfer number of files')
      @@metric_nbfiles_failed = Prometheus::Client::Gauge.new(:txnbfilesfailed, docstring: 'SPLASH metric transfer number of failed files')
      @@metric_time = Prometheus::Client::Gauge.new(:txtime, docstring: 'SPLASH metric transfer execution time')
      @@registry.register(@@metric_nbfiles)
      @@registry.register(@@metric_nbfiles_failed)
      @@registry.register(@@metric_time)

      def initialize(options={})
        @config = get_config
        @url = @config.prometheus_pushgateway_url
        @name = "tx_#{options[:name].to_s}"
        @nbfiles = options[:nbfiles]
        @nbfiles_failed = options[:nbfiles_failed]
        @time = options[:time]
      end

      # send metrics to Prometheus PushGateway
      # @return [Bool]
      def notify
	unless verify_service url: @url then
          return { :case => :service_dependence_missing, :more => "Prometheus Notification not send."}
        end
        @@metric_nbfiles.set(@nbfiles)
        @@metric_nbfiles_failed.set(@nbfiles_failed)
        @@metric_time.set(@time)
        hostname = Socket.gethostname
        return Prometheus::Client::Push.new(@name, hostname, @url).add(@@registry)
      end

    end



    class TxRecords
      include Splash::Backends
      include Splash::Constants

      def initialize(name)
        @name = name
        @backend = get_backend :transfers_trace
      end

      def purge(retention)
        retention = {} if retention.nil?
        if retention.include? :hours then
          adjusted_datetime = DateTime.now - retention[:hours].to_f / 24
        elsif retention.include? :hours then
          adjusted_datetime = DateTime.now - retention[:days].to_i
        else
          adjusted_datetime = DateTime.now - DEFAULT_RETENTION
        end

        data = get_all_records

        data.delete_if { |item|
          DateTime.parse(item.keys.first) <= (adjusted_datetime)}
        @backend.put key: @name, value: data.to_yaml
      end

      def add_record(record)
        data = get_all_records
        data.push({ DateTime.now.to_s => record })
        @backend.put key: @name, value: data.to_yaml
      end

      def get_all_records(options={})
        return (@backend.exist?({key: @name}))? YAML::load(@backend.get({key: @name})) : []
      end

      def check_prepared
        return :never_run_prepare unless @backend.exist?({key: @name})
        return :never_prepare unless YAML::load(@backend.get({key: @name})).select {|item|
          record =item.keys.first
          value=item[record]
          value[:status] == :prepared
        }.count > 0
        return :prepared
      end

    end

    def run_txs(options = {})
      log = get_logger
      log.info 'Running Transfers'
      count=0
      get_config.transfers.each do |record|
        txrec =  TxRecords::new record[:name]
        txrec.purge(record[:retention])
        log.item "Execute : #{record[:name]},  #{record[:desc]}"
        case txrec.check_prepared
        when :prepared
          if record[:type] == :push then
            unless push record
              count += 1
            end
          elsif record[:type] == :pull then
            unless pull record
              count += 1
            end
          else
            log.ko "Transfer type unkown"
            count += 1
          end
        when :never_prepare
          log.ko "#{record[:name]} : Never prepared, ignored"
          txrec.add_record :status => :never_prepared
          count += 1
        when :never_run_prepare
          log.ko "#{record[:name]} : Never Executed and never prepared, ignored"
          txrec.add_record :status => :never_prepared
          count += 1
        end
      end
      return {:case => :error_exit, :more => "#{count} Transfer(s) failed"} if count > 0
      return {:case => :quiet_exit }
    end



    def prepare_tx(name)
      log = get_logger
      record = get_config.transfers.select { |item| item[:name] == name.to_sym }.first
      home  = Etc.getpwnam(record[:local][:user]).dir
      identity = ::File::readlines("#{home}/.ssh/id_rsa.pub").first.chomp
      folder  = {:mode => "755",
                 :owner => record[:local][:user] ,
                 :group => Etc.getgrgid(Etc.getpwnam(record[:local][:user]).gid).name,
                 :name => record[:local][:path],
                 :path => record[:local][:path]}
      log.info "Ensure local folder : #{record[:local][:path]}"
      make_folder(folder) unless verify_folder(folder).empty?
      begin
        log.info "Ensure RSA Key sharing for local user : #{record[:local][:user]} to remote user : #{record[:remote][:user]}@#{record[:remote][:host]}"
        ssh = Net::SSH.start(record[:remote][:host],record[:remote][:user])
        output = ssh.exec!(%[
          /bin/bash -cl '
          umask 077;
          mkdir #{record[:remote][:path]};
          test -d ~/.ssh || mkdir ~/.ssh;
          if [ ! -f ~/.ssh/authorized_keys -o `grep "#{identity}" ~/.ssh/authorized_keys 2> /dev/null | wc -l` -eq 0 ]; then              echo "#{identity}" >> ~/.ssh/authorized_keys
          fi'])
        log.info "Prepare remote folder : #{record[:remote][:path]}"
        log.info "Prepare data file for transfer : #{record[:name]}"
        txrec = TxRecords::new record[:name]
        txrec.add_record :status => :prepared
        log.ok "Transfer : #{record[:name]} prepared successfully"
        return {:case => :quiet_exit }
      rescue Interrupt
        splash_exit case: :interrupt, more: "Remote command exection"
      rescue TTY::Reader::InputInterrupt
        splash_exit case: :interrupt, more: "Remote command exection"
      end
    end



    def save_data

    end



    def push(record)
      config = get_config
      log = get_logger
      txrec = TxRecords::new record[:name]
      start = Time.now
      res = true
      count = 0
      done =[]
      start_date = DateTime.now.to_s
      list = Dir.glob("#{record[:local][:path]}/#{record[:pattern]}")
      count = list.count
      log.arrow "Transfering #{count} file(s)"

      begin
        scp = Net::SCP.start(record[:remote][:host],record[:remote][:user])
        list.each do|f|
          log.arrow "Copy file : #{f} to #{record[:remote][:user]}@#{record[:remote][:host]}:#{record[:remote][:path]}"
          scp.upload! f, record[:remote][:path]
          done.push f
          if record[:backup] then
            log.arrow "File #{f} backuped"
            FileUtils::mv(f, "#{f}.#{Time.now.getutc.to_i}")
          else
            FileUtils::unlink(f)
          end
        end

      rescue
        res = false
      end

      end_date = DateTime.now.to_s
      time = Time.now - start
      status = (res)? :success : :failure
      txrec.add_record :status => status,
                       :end_date => end_date,
                       :time => time,
                       :count => count,
                       :wanted => list,
                       :done => done
      count_failed = list.count - done.count
      txmonitor = TxNotifier::new({name: record[:name], nbfiles: count,nbfiles_failed: count_failed, time: time})
      if txmonitor.notify then
        log.ok "Sending metrics to Prometheus Pushgateway"
      else
        log.ko "Failed to send metrics to Prometheus Pushgateway"
      end
      return res
    end
  end
end
