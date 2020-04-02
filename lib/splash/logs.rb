class LogScanner
  CONFIG_FILE = '/etc/splash.yml'
  def readconf(file = CONFIG_FILE)
    @logs_target = YAML.load_file(file)[:logs]
  end

  def initialize(config_file)
    readconf(config_file)
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
    registry = Prometheus::Client.registry
    metric = Prometheus::Client::Gauge.new(:logerror, docstring: 'SPLASH metric log error', labels: [:log ])
    registry.register(metric)
    @logs_target.each do |item|
      metric.set(item[:count], labels: { log: item[:log] })
    end
    Prometheus::Client::Push.new('Splash').add(registry)
  end

end
