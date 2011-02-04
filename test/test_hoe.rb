require 'minitest/autorun'
require 'hoe'
require 'tempfile'

$rakefile = nil # shuts up a warning in rdoctask.rb

class TestHoe < MiniTest::Unit::TestCase
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
    hoe = Hoe.spec 'blah' do
      developer 'author', 'email'
    end

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

    Dir.mktmpdir do |path|
      ENV['HOME'] = path
      $LOAD_PATH << path

      Dir.mkdir File.join(path, 'hoe')
      open File.join(path, 'hoe', 'hoerc.rb'), 'w' do |io|
        io.write 'module Hoe::Hoerc; def initialize_hoerc; end; end'
      end

      open File.join(path, '.hoerc'), 'w' do |io|
        io.write YAML.dump 'plugins' => %w[hoerc]
      end

      spec = Hoe.spec 'blah' do
        developer 'author', 'email'
      end

      methods = spec.methods.grep(/^initialize/).map { |s| s.to_s }

      assert_includes methods, 'initialize_hoerc'
    end
  ensure
    Hoe.instance_variable_get(:@loaded).delete :hoerc
    Hoe.plugins.delete :hoerc
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

  def test_possibly_better
    t = Gem::Specification::TODAY
    hoe = Hoe.spec("blah") do
      self.version = '1.2.3'
      developer 'author', 'email'
    end

    files = File.read("Manifest.txt").split(/\n/) + [".gemtest"]

    spec = hoe.spec

    text_files = files.grep(/txt$/).reject { |f| f =~ /template/ }

    assert_equal 'blah', spec.name
    assert_equal '1.2.3', spec.version.to_s
    assert_equal '>= 0', spec.required_rubygems_version.to_s

    assert_equal ['author'], spec.authors
    assert_equal t, spec.date
    assert_equal 'sow', spec.default_executable
    assert_match(/Hoe.*Rakefiles/, spec.description)
    assert_equal ['email'], spec.email
    assert_equal ['sow'], spec.executables
    assert_equal text_files, spec.extra_rdoc_files
    assert_equal files, spec.files
    assert_equal true, spec.has_rdoc
    assert_equal "http://rubyforge.org/projects/seattlerb/", spec.homepage
    assert_equal ['--main', 'README.txt'], spec.rdoc_options
    assert_equal ['lib'], spec.require_paths
    assert_equal 'blah', spec.rubyforge_project
    assert_equal Gem::RubyGemsVersion, spec.rubygems_version
    assert_match(/^Hoe.*Rakefiles$/, spec.summary)
    assert_equal files.grep(/^test/), spec.test_files

    deps = spec.dependencies.sort_by { |dep| dep.name }

    expected = [["hoe",       :development, ">= #{Hoe::VERSION}"]]

    expected << ["rubyforge", :development, ">= #{::RubyForge::VERSION}"] if
      defined? ::RubyForge

    assert_equal expected, deps.map { |dep|
      [dep.name, dep.type, dep.requirement.to_s]
    }
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

    assert_equal %w(    word      word     Word),  Hoe.normalize_names('word')
    assert_equal %w(    word      word     Word),  Hoe.normalize_names('Word')
    assert_equal %w(two_words two_words TwoWords), Hoe.normalize_names('TwoWords')
    assert_equal %w(two_words two_words TwoWords), Hoe.normalize_names('twoWords')
    assert_equal %w(two_words two_words TwoWords), Hoe.normalize_names('two-words')
    assert_equal %w(two_words two_words TwoWords), Hoe.normalize_names('two_words')
  end
end
