# coding: utf-8
module CLISplash

  class Documentation < Thor
    include Splash::Config
    include Splash::Exiter


    desc "readme", "Display README file"
    option :formatted, :type => :boolean, :default => true
    def readme
      filename = search_file_in_gem("prometheus-splash","README.md")

      if options[:formatted] then
        content = TTY::Markdown.parse_file(filename)
      else
        conten = File::readlines(filename).join
      end
      pager = TTY::Pager.new
      pager.page(content)
      splash_exit case: :quiet_exit
    end
  end
end
