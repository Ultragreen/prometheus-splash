module Splash
  module Templates
    class Template

      attr_reader :list_token
      attr_reader :template_file
      attr_reader :content

      def initialize(_options)


        @template_file = _options[:template_file]
        raise NoTemplateFile::new('No template file found') unless File::exist?(@template_file)
        begin
          @content = IO::readlines(@template_file).join.chomp
        rescue
          raise NoTemplateFile::new('No template file found')
        end
        token_from_template = @content.scan(/%%(\w+)%%/).flatten.uniq.map{ |item| item.downcase.to_sym}
        begin
          @list_token = _options[:list_token]
          @hash_token = Hash::new; @list_token.each{|_item| @hash_token[_item.to_s] = String::new('')}
        rescue
          raise InvalidTokenList::new("Token list malformation")
        end
        raise InvalidTokenList::new("Token list doesn't match the template") unless token_from_template.sort == @list_token.sort
        @list_token.each{|_token| eval("def #{_token}=(_value); raise ArgumentError::new('Not a String') unless _value.class == String; @hash_token['#{_token}'] = _value ;end")}
        @list_token.each{|_token| eval("def #{_token}; @hash_token['#{_token}'] ;end")}
      end

      def token(_token,_value)
        raise ArgumentError::new('Not a String') unless _value.class == String
        @hash_token[_token.to_s] = _value
      end


      def map(_hash)
        _data = {}
        _hash.each { |item,val|
          raise ArgumentError::new("#{item} : Not a String") unless val.class == String
          _data[item.to_s.downcase] = val
        }
        raise InvalidTokenList::new("Token list malformation") unless _data.keys.sort == @list_token.map{|_token| _token.to_s }.sort
        @hash_token = _data
      end

      def method_missing(_name,*_args)
        raise NotAToken
      end


      def output
        _my_res = String::new('')
        _my_res = @content
        @list_token.each{|_token|
          _my_res.gsub!(/%%#{_token.to_s.upcase}%%/,@hash_token[_token.to_s])
        }
        return _my_res
      end

    end

    class InvalidTokenList < Exception; end
    class NotAToken < Exception; end
    class NoTemplateFile < Exception; end

  end
end
