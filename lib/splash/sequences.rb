# coding: utf-8

# base Splash module
module Splash

  # Splash Commands module/namespace
  module Sequences

    include Splash::Commands
    include Splash::Config
    include Splash::Loggers
    include Splash::Exiter
    include Splash::Transports

    def run_seq(params = {})
      list = get_config.sequences
      name = params[:name].to_sym
      acase = {}
      seq_res = []
      log = get_logger
      log.info "beginnning Sequence execution : #{name}"
      session = (params[:session])? params[:session] : get_session
      if list.include? name then
        seq_options = (list[name][:options].nil?)? {} : list[name][:options]
        list[name][:definition].each do |step|
          log.info "STEP : #{step[:step]}",session
          if step[:on_host].nil? then
            command =  CommandWrapper::new(step[:command].to_s)
              step[:callback] = true if step[:callback].nil?
              step[:trace] = true if step[:trace].nil?
              step[:notify] = true if step[:notify].nil?
              step[:session] = session
              acase = command.call_and_notify step
          else
            log.info "Remote execution of #{step[:command]} on #{step[:on_host]}", session
            begin
              transport = get_default_client
              if transport.class == Hash  and transport.include? :case then
                return transport
              else
                acase = transport.execute({ :verb => :execute_command,
                                          payload: {:name => step[:command].to_s},
                                         :return_to => "splash.#{Socket.gethostname}.return",
                                         :queue => "splash.#{step[:on_host]}.input" })
                log.receive "return with exitcode #{acase[:exit_code]}", session
              end
            rescue Interrupt
              acase = { case: :interrupt, more: "Remote command exection", exit_code: 33}
            end

           end
           seq_res.push acase[:exit_code]
           continue = (seq_options[:continue].nil?)? true : seq_options[:continue]
           if acase[:exit_code] > 0 and continue == false then
             acase[:more] = "Break execution on error, continue = false"
             break
           end
        end
      else
        return  { :case => :not_found, :more => "Sequence #{name} not configured" }
      end

      if seq_res.select {|res| res > 0}.count == seq_res.count then
        acase =  { case: :status_ko, more: "all execution failed" }
      elsif seq_res.select {|res| res > 0}.count > 0 then
        acase =  { case: :status_ko, more: "some execution failed" }
      else
        acase =  { case: :status_ok, more: "all execution successed" }
      end
      acase[:more] << " with remote call interrupt" if seq_res.include?(33)
      return acase
    end


    def list_seq(options = {})
      list = get_config.sequences
      unless list.empty?
        acase = { :case =>  :quiet_exit , :more => "List configured sequences"}
        acase[:data] = list
        return acase
      else
        return { :case => :not_found, :more => 'No sequences configured' }
      end
    end

    def show_seq(options = {})
      list = get_config.sequences
      name = options[:name].to_sym
      if list.include? name then
        acase = { :case => :quiet_exit, :more => "Show specific sequence : #{name}"}
        acase[:data] = list[name]
      else
        return { :case => :not_found, :more => "Sequence #{name} not configured" }
      end
      return acase
    end

    def schedule_seq(options = {})
      acase = { :case => :quiet_exit,  :more => "schedule" }
      return acase

    end

  end
end
