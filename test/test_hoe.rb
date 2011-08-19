require 'minitest/autorun'
require 'hoe'
require 'tempfile'

class Hoe
  def self.files= x
    @files = x
  end
end

$rakefile = nil # shuts up a warning in rdoctask.rb

class TestHoe < MiniTest::Unit::TestCase
  def hoe
    @hoe ||= Hoe.spec("blah") do
      developer 'author', 'email'
    end
  end

  def setup
    Rake.application.clear
  end

  def test_class_load_plugins
    loaded, = Hoe.load_plugins

    assert_includes loaded.keys, :clean
    assert_includes loaded.keys, :debug
    assert_includes loaded.keys, :deps
  end

  def test_activate_plugins
    initializers = hoe.methods.grep(/^initialize/).map { |s| s.to_s }

    assert_includes initializers, 'initialize_clean'
    assert_includes initializers, 'initialize_flay'
    assert_includes initializers, 'initialize_flog'
    assert_includes initializers, 'initialize_package'
    assert_includes initializers, 'initialize_publish'
    assert_includes initializers, 'initialize_test'
  end

  def test_activate_plugins_hoerc
    home = ENV['HOME']
    load_path = $LOAD_PATH.dup
    Hoe.files = nil

    Dir.mktmpdir do |path|
      ENV['HOME'] = path
      $LOAD_PATH << path

      Dir.mkdir File.join(path, 'hoe')
      open File.join(path, 'hoe', 'hoerc.rb'), 'w' do |io|
        io.write 'module Hoe::Hoerc; def initialize_hoerc; end; end'
      end

      open File.join(path, '.hoerc'), 'w' do |io|
        io.write YAML.dump('plugins' => %w[hoerc])
      end

      methods = hoe.methods.grep(/^initialize/).map { |s| s.to_s }

      assert_includes methods, 'initialize_hoerc'
    end
  ensure
    Hoe.instance_variable_get(:@loaded).delete :hoerc
    Hoe.plugins.delete :hoerc
    Hoe.send :remove_const, :Hoerc
    $LOAD_PATH.replace load_path
    ENV['HOME'] = home
  end

  def test_initialize_plugins_hoerc
    home = ENV['HOME']
    load_path = $LOAD_PATH.dup
    Hoe.files = nil

    Dir.mktmpdir do |path|
      ENV['HOME'] = path
      $LOAD_PATH << path

      Dir.mkdir File.join(path, 'hoe')
      open File.join(path, 'hoe', 'hoerc.rb'), 'w' do |io|
        io.write 'module Hoe::Hoerc; def initialize_hoerc; @hoerc_plugin_initialized = true; end; end'
      end

      open File.join(path, '.hoerc'), 'w' do |io|
        io.write YAML.dump('plugins' => %w[hoerc])
      end

      methods = hoe.instance_variables.map(&:to_s)
      assert_includes(methods, '@hoerc_plugin_initialized',
                      "Hoerc plugin wasn't initialized")
    end
  ensure
    Hoe.instance_variable_get(:@loaded).delete :hoerc
    Hoe.plugins.delete :hoerc
    Hoe.send :remove_const, :Hoerc
    $LOAD_PATH.replace load_path
    ENV['HOME'] = home
  end

  def test_file_read_utf
    Tempfile.open 'BOM' do |io|
      io.write "\xEF\xBB\xBFBOM"
      io.rewind
      assert_equal 'BOM', File.read_utf(io.path)
    end
  end

  def test_parse_urls_ary
    ary  = ["* https://github.com/seattlerb/hoe",
            "* http://seattlerb.rubyforge.org/hoe/",
            "* http://seattlerb.rubyforge.org/hoe/Hoe.pdf",
            "* http://github.com/jbarnette/hoe-plugin-examples"].join "\n"

    exp = ["https://github.com/seattlerb/hoe",
           "http://seattlerb.rubyforge.org/hoe/",
           "http://seattlerb.rubyforge.org/hoe/Hoe.pdf",
           "http://github.com/jbarnette/hoe-plugin-examples"]

    assert_equal exp, hoe.parse_urls(ary)
  end

  def test_parse_urls_hash
    hash = [
            "home  :: https://github.com/seattlerb/hoe",
            "rdoc  :: http://seattlerb.rubyforge.org/hoe/",
            "doco  :: http://seattlerb.rubyforge.org/hoe/Hoe.pdf",
            "other :: http://github.com/jbarnette/hoe-plugin-examples",
           ].join "\n"

    exp = {
      "home"  => "https://github.com/seattlerb/hoe",
      "rdoc"  => "http://seattlerb.rubyforge.org/hoe/",
      "doco"  => "http://seattlerb.rubyforge.org/hoe/Hoe.pdf",
      "other" => "http://github.com/jbarnette/hoe-plugin-examples",
    }

    assert_equal exp, hoe.parse_urls(hash)
  end

  def test_possibly_better
    t = Gem::Specification::TODAY
    hoe = Hoe.spec("blah") do
      self.version = '1.2.3'
      developer 'author', 'email'
    end

    files = File.read("Manifest.txt").split(/\n/) + [".gemtest"]

    spec = hoe.spec

    urls = {
      "home"  => "https://github.com/seattlerb/hoe",
      "rdoc"  => "http://seattlerb.rubyforge.org/hoe/",
      "doco"  => "http://seattlerb.rubyforge.org/hoe/Hoe.pdf",
      "other" => "http://github.com/jbarnette/hoe-plugin-examples",
    }

    assert_equal "https://github.com/seattlerb/hoe", hoe.url
    assert_equal urls, hoe.urls

    text_files = files.grep(/txt$/).reject { |f| f =~ /template/ }

    assert_equal 'blah', spec.name
    assert_equal '1.2.3', spec.version.to_s
    assert_equal '>= 0', spec.required_rubygems_version.to_s

    assert_equal ['author'], spec.authors
    assert_equal t, spec.date
    assert_match(/Hoe.*Rakefiles/, spec.description)
    assert_equal ['email'], spec.email
    assert_equal ['sow'], spec.executables
    assert_equal text_files, spec.extra_rdoc_files
    assert_equal files, spec.files
    assert_equal "https://github.com/seattlerb/hoe", spec.homepage
    # TODO: assert_equal "https://github.com/seattlerb/hoe", spec.metadata
    assert_equal ['--main', 'README.txt'], spec.rdoc_options
    assert_equal ['lib'], spec.require_paths
    assert_equal 'blah', spec.rubyforge_project
    assert_equal Gem::RubyGemsVersion, spec.rubygems_version
    assert_match(/^Hoe.*Rakefiles$/, spec.summary)
    assert_equal files.grep(/^test/).sort, spec.test_files.sort

    deps = spec.dependencies.sort_by { |dep| dep.name }

    expected = [["hoe", :development, "~> #{Hoe::VERSION.sub(/\.\d+$/, '')}"]]

    expected << ["rubyforge", :development, ">= #{::RubyForge::VERSION}"] if
      defined? ::RubyForge

    assert_equal expected, deps.map { |dep|
      [dep.name, dep.type, dep.requirement.to_s]
    }

    # flunk "not yet"
  end

  def test_plugins
    before = Hoe.plugins.dup
    Hoe.plugin :first, :second
    assert_equal before + [:first, :second], Hoe.plugins
    Hoe.plugin :first, :second
    assert_equal before + [:first, :second], Hoe.plugins
  ensure
    Hoe.plugins.replace before
  end

  def test_rename
    # project, file_name, klass = Hoe.normalize_names 'project_name'

    assert_equal %w(    word      word     Word),    Hoe.normalize_names('word')
    assert_equal %w(    word      word     Word),    Hoe.normalize_names('Word')
    assert_equal %w(two_words two_words TwoWords),   Hoe.normalize_names('TwoWords')
    assert_equal %w(two_words two_words TwoWords),   Hoe.normalize_names('twoWords')
    assert_equal %w(two-words two/words Two::Words), Hoe.normalize_names('two-words')
    assert_equal %w(two_words two_words TwoWords),   Hoe.normalize_names('two_words')
  end

  def test_nosudo
    hoe = Hoe.spec("blah") do
      self.version = '1.2.3'
      developer 'author', 'email'

      def sh cmd
        cmd
      end
    end

    assert_match(/^(sudo )?j?gem.*/, hoe.install_gem('foo'))
    ENV['NOSUDO'] = '1'
    assert_match(/^j?gem.*/, hoe.install_gem('foo'))
  ensure
    ENV.delete "NOSUDO"
  end
end
