module Splash
  class LogScanner
    include Splash::Constants
    include Splash::Config

    def initialize
      @logs_target = get_config.logs

      @registry = Prometheus::Client.registry
      @metric = Prometheus::Client::Gauge.new(:logerror, docstring: 'SPLASH metric log error', labels: [:log ])
      @registry.register(@metric)
    end

    def analyse
      @logs_target.each do |record|
        record[:count]=0 if record[:count].nil?
        record[:status] = :clean if record[:status].nil?
        if File.exist?(record[:log]) then
          record[:count] = File.readlines(record[:log]).grep(/#{record[:pattern]}/).size
          record[:status] = :matched if record[:count] > 0
        else
          record[:status] = :mssing
        end
      end
    end

    def output
      return @logs_target
    end

    def notify
      @logs_target.each do |item|
        @metric.set(item[:count], labels: { log: item[:log] })
      end
      Prometheus::Client::Push.new('Splash').add(@registry)
    end

  end
end
