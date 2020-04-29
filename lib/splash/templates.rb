# coding: utf-8

# base Splash Module
module Splash

  # Templates namespace
  module Templates

    # KISS template Engine
    class Template

      # getter of the list of token
      attr_reader :list_token
      # getter of the template file
      attr_reader :template_file
      # getter of the flat content of the template
      attr_reader :content

      # constructor : generate the pseudo accessor for template Class from token list
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

      # generic accessor
      # @param [Symbol] _token in the token list
      # @param [String] _value a text value
      # @raise [ArgumentError] if _valu is not a String
      def token(_token,_value)
        raise ArgumentError::new('Not a String') unless _value.class == String
        @hash_token[_token.to_s] = _value
      end

      # map a hash against templates token_list
      # @param [Hash] _hash a hash data to map
      def map(_hash)
        _data = {}
        _hash.each { |item,val|
          raise ArgumentError::new("#{item} : Not a String") unless val.class == String
          _data[item.to_s.downcase] = val
        }
        raise InvalidTokenList::new("Token list malformation") unless _data.keys.sort == @list_token.map{|_token| _token.to_s }.sort
        @hash_token = _data
      end

      # collector for pseudo accessor to prevent bad mapping
      # @raise [NotAToken] if caling an accessor not mapped in token list
      def method_missing(_name,*_args)
        raise NotAToken
      end

      # the templater;proceed to templating
      # @return [String] the template output
      def output
        _my_res = String::new('')
        _my_res = @content
        @list_token.each{|_token|
          _my_res.gsub!(/%%#{_token.to_s.upcase}%%/,@hash_token[_token.to_s])
        }
        return _my_res
      end

    end

    # Exception for an invalid Token list
    class InvalidTokenList < Exception; end
    # Exception for an malformed token
    class NotAToken < Exception; end
    # Exception for an invalid template file
    class NoTemplateFile < Exception; end

  end
end
