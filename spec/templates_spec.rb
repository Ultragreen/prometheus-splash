require_relative '../lib/splash/templates'

include Splash::Templates

describe Template do
  $template_file = "/tmp/template.txt"
  $nonexistantfile = "/tmp/nonexistant.txt"
  $template = "Hello %%NAME%% !!"
  $result = "Hello Romain !!"
  $goodtoken = :name
  $badtoken = :surname
  $value = 'Romain'
  before :all do
    `echo "#{$template}" > #{$template_file}`
    File::unlink($nonexistantfile) if File::exist?($nonexistantfile)
  end
  subject { Template }
  specify { should be_an_instance_of Class }
  context "Exception case" do
    it "should raise NoTemplateFile if template file not exist" do
      expect { Template::new({:list_token => [$goodtoken] , :template_file => $nonexistantfile}) }.to raise_error NoTemplateFile
    end
    it "should raise NotAToken if try to send ##{$badtoken} and '#{$badtoken}' not a valid token" do
      expect { Template::new({ :list_token => [$goodtoken], :template_file => $template_file}).send($badtoken.to_sym)}.to raise_error NotAToken
    end
    it "should raise InvalidTokenList if initialized with ['#{$goodtoken}','#{$badtoken}'] tokens list" do
      expect { Template::new({ :list_token => [$goodtoken,$badtoken] , :template_file => $template_file})}.to raise_error InvalidTokenList
    end
    it "should raise NoTemplateFile if template file not exist AND initialized with ['#{$goodtoken}','#{$badtoken}'] tokens list" do
      expect { Template::new({ :list_token => [$goodtoken,$badtoken] , :template_file => $nonexistantfile})}.to raise_error NoTemplateFile
    end
  end

  context "Template <execution> with token '#{$goodtoken}', content = '#{$content}', and ##{$goodtoken}='#{$value}'" do
    before :all do
      $test = Template::new({ :list_token => [$goodtoken] , :template_file => $template_file})
    end
    context "#content" do
      specify {expect($test.content).to be_an_instance_of String }
      it "should have '#{$template}' in #content" do
        expect( $test.content).to eq($template)
      end
      specify {expect($test).to_not respond_to 'content=' }
    end
    context "#token_list" do
      specify {expect($test.list_token).to be_an_instance_of Array }
      it "should have ['#{$goodtoken}'] in #list_token" do
        expect($test.list_token).to eq([$goodtoken])
      end
      specify { expect($test).to_not respond_to 'token_list=' }
    end
    context "virtual (methode_missing) #{$goodtoken}" do
      specify { expect($test.send($goodtoken.to_sym)).to be_an_instance_of String }
      specify { expect($test).to respond_to(:name) }
      specify { $test.name = $value; expect($test.name).to eq($value) }
      it "should raise ArgumentError if virtual methode '#name=' got non String arguement (accessor)" do
        expect { $test.name = 1 }.to raise_error ArgumentError
      end
    end
    context "#output" do
      it "should #output 'Hello Romain !!' if set #name = 'Romain' and msg send #output" do
        $test.name = 'Romain'
        expect( $test.output).to eq('Hello Romain !!')
      end
      specify { expect($test).to_not respond_to 'output=' }
    end
    after :all do
      File::unlink($template_file) if File::exist?($template_file)
      $test = nil
    end
  end
end
