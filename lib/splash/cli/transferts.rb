# coding: utf-8

# module for all Thor subcommands
module CLISplash

  # Thor inherited class for transferts management
  class Transferts < Thor
    include Splash::Transferts
    include Splash::Helpers
    include Splash::Exiter
    include Splash::Loggers



    # Thor method : running tranferts prepare
    long_desc <<-LONGDESC
    Prepare tranferts with RSA Public key\n
    LONGDESC
    desc prepare(name), "Prepare tranferts with RSA Public key"
    Warning : interactive command only (prompt for passwd)
    def
      tx = Manager.new
      unless is_root?
        return {:case => :not_root, :more => "subcommands : prepare"}
      else
        splash_exit tx.prepare_tx(name)
      end
    end




  end

end
