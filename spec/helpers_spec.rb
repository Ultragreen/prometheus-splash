require_relative '../lib/splash/dependencies'

include Splash

describe Helpers do
  $test_file = "./test.txt"
  $test_target = './test_target.txt'
  `echo 'test' > #{$test_file}`
  $nonexistantfile = "./no.txt"
  $test_folder = "./test_folder"
  $symlink = "./test_link"
  before :all do
    File::unlink($nonexistantfile) if File::exist?($nonexistantfile)
  end

  after :all do
    File::unlink($test_target) if File::exist?($test_target)
    FileUtils::rm($symlink) if File::exist?($symlink)
    FileUtils::rmdir($test_folder) if File::exist?($test_folder)
    File::unlink($test_file) if File::exist?($test_file)

  end


  subject { Helpers }
  specify { should be_an_instance_of Module }
  context "Misc functions" do
    include Splash::Helpers
    describe '#user_root' do
      specify { expect(self).to respond_to 'user_root' }
      specify { expect(['root']).to include(user_root) }
    end

    describe '#group_root' do
      specify { expect(self).to respond_to 'group_root' }
      specify { expect(['root','wheel']).to include(user_root) }
    end

    describe '#get_processes' do
      specify { expect(self).to respond_to 'get_processes' }
      specify { expect(get_processes(pattern: '/usr')).to  be_an_instance_of Array }
      specify { expect(get_processes(patterns: ['/usr'])).to  be_an_instance_of Array }
      specify { expect(get_processes(pattern: '/usr').first).to  be_an_instance_of String }
      specify { expect(get_processes(pattern: '/usr', full: true).first).to  be_an_instance_of PsProcess }
    end

    describe '#search_file_in_gem' do
      specify { expect(self).to respond_to 'search_file_in_gem' }
      specify { expect(search_file_in_gem('prometheus-splash','config/splash.yml')).to be_an_instance_of String }
      specify { expect(search_file_in_gem('prometheus-splash','config/splash.yml')).to include('config/splash.yml') }
    end

    describe '#is_root?' do
      specify { expect(self).to respond_to 'is_root?' }
      specify { expect(is_root?).to eq(false) }
    end

    describe '#run_as_root' do
      specify { expect(self).to respond_to 'run_as_root' }
      specify { expect(run_as_root(:user_root)).to eq({:case => :not_root, :more => "subcommands : user_root"}) }
    end

  end

  context "FS functions" do
    include Splash::Helpers
    describe '#install_file' do
      specify { expect(self).to respond_to 'install_file' }
      specify { expect(install_file(source: $test_file, target: $test_target, mode: "777" )).to eq(true) }
    end

    describe '#make_folder' do
      specify { expect(self).to respond_to 'make_folder' }
      specify { expect(make_folder(path: $test_folder, mode: "777" )).to eq(true) }
    end

    describe '#make_link' do
      specify { expect(self).to respond_to 'make_link' }
      specify { expect(make_link(source: $test_file, link: $symlink )).to eq(true) }
    end

  end

  context "FS checkers" do
    include Splash::Helpers
    describe '#verify_file' do
      specify { expect(self).to respond_to 'verify_file' }
      specify { expect(verify_file(name: $test_file, mode: "777" )).to be_an_instance_of Array  }
      specify { expect(verify_file(name: $test_target, mode: "777" )).to be_empty }
      specify { expect(verify_file(name: $test_file, mode: "700" )).to include(:mode) }
      specify { expect(verify_file(name: $nonexistantfile, mode: "777" )).to include(:inexistant) }
    end

    describe '#verify_folder' do
      specify { expect(self).to respond_to 'verify_folder' }
      specify { expect(verify_folder(name: $test_folder, mode: "777" )).to be_an_instance_of Array  }
      specify { expect(verify_folder(name: $test_folder, mode: "777" )).to be_empty }
      specify { expect(verify_folder(name: $test_folder, mode: "700" )).to include(:mode) }
      specify { expect(verify_folder(name: $nonexistantfile, mode: "777" )).to include(:inexistant) }
    end

    describe '#verify_link' do
      specify { expect(self).to respond_to 'verify_link' }
      specify { expect(verify_link(name: $nonexistantfile)).to eq(false) }
      specify { expect(verify_link(name: $symlink)).to eq(true) }
    end

  end

  context "Service checker" do
    include Splash::Helpers
    describe '#verify_service' do
      specify { expect(self).to respond_to 'verify_service' }
      specify { expect(verify_service(host: 'localhost', port: '7777')).to eq(false) }
      specify { expect(verify_service(host: 'github.com', port: '80')).to eq(true) }
    end
  end

end
