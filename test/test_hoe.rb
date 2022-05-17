# coding: utf-8
require "minitest/autorun"
require "hoe"
require "tempfile"

class Hoe
  def self.files= x
    @files = x
  end
end

$rakefile = nil # shuts up a warning in rdoctask.rb

class TestHoe < Minitest::Test
  def hoe *skips, &b
    @hoe ||= Hoe.spec "blah" do
      developer "author", "email"
      license "MIT"                      unless skips.include? :skip_license
      self.version      = "1.0"          unless skips.include? :skip_version
      self.readme_file  = "README.rdoc"  unless skips.include? :skip_files
      self.history_file = "History.rdoc" unless skips.include? :skip_files
      self.instance_eval(&b) if b
    end
  end

  def teardown
    Rake.application.clear

    Hoe.plugins.clear
    Hoe.bad_plugins.clear
    Hoe.instance_variable_set :@files, nil
    Hoe.instance_variable_set :@found, nil
    Hoe.instance_variable_set :@loaded, nil

    Hoe.plugin :package
    Hoe.plugin :publish
    Hoe.plugin :test
  end

  def test_class_bad_plugins
    Hoe.plugin :bogus

    Hoe.load_plugins

    assert_equal [:bogus], Hoe.bad_plugins

    Hoe.load_plugins

    assert_equal [:bogus], Hoe.bad_plugins
  end

  def test_class_load_plugins
    loaded, = Hoe.load_plugins

    assert_includes loaded.keys, :package
    assert_includes loaded.keys, :publish
    assert_includes loaded.keys, :test
  end

  def test_activate_plugins
    initializers = hoe.methods.grep(/^initialize/).map(&:to_s)

    assert_includes initializers, "initialize_package"
    assert_includes initializers, "initialize_publish"
    assert_includes initializers, "initialize_test"
  end

  def test_activate_plugins_hoerc
    home = ENV["HOME"]
    load_path = $LOAD_PATH.dup
    Hoe.files = nil

    Dir.mktmpdir do |path|
      ENV["HOME"] = path
      $LOAD_PATH << path

      Dir.mkdir File.join(path, "hoe")
      open File.join(path, "hoe", "hoerc.rb"), "w" do |io|
        io.write <<-EOM
          module Hoe::Hoerc
            def initialize_hoerc; end
            def define_hoerc_tasks; end
          end
        EOM
      end

      write_hoerc path, "plugins" => %w[hoerc]

      methods = hoe.methods.grep(/^initialize/).map(&:to_s)

      assert_includes methods, "initialize_hoerc"
      assert_includes Hoe.plugins, :hoerc
    end
  ensure
    reset_hoe load_path, home
  end

  def test_have_gem_eh
    assert hoe.have_gem? "rake"
    refute hoe.have_gem? "nonexistent"
  end

  def test_initialize_plugins_hoerc
    home = ENV["HOME"]
    load_path = $LOAD_PATH.dup
    Hoe.files = nil

    Dir.mktmpdir do |path|
      ENV["HOME"] = path
      $LOAD_PATH << path

      Dir.mkdir File.join(path, "hoe")
      open File.join(path, "hoe", "hoerc.rb"), "w" do |io|
        io.write <<-EOM
          module Hoe::Hoerc
            def initialize_hoerc; @hoerc_plugin_initialized = true; end
            def define_hoerc_tasks; end
          end
        EOM
      end

      write_hoerc path, "plugins" => %w[hoerc]

      methods = hoe.instance_variables.map(&:to_s)
      assert_includes(methods, "@hoerc_plugin_initialized",
                      "Hoerc plugin wasn't initialized")
      assert_includes Hoe.plugins, :hoerc
    end
  ensure
    reset_hoe load_path, home
  end

  def write_hoerc path, data
    open File.join(path, ".hoerc"), "w" do |io|
      io.write YAML.dump data
    end
  end

  def reset_hoe load_path, home
    Hoe.instance_variable_get(:@loaded).delete :hoerc
    Hoe.plugins.delete :hoerc
    Hoe.send :remove_const, :Hoerc
    $LOAD_PATH.replace load_path
    ENV["HOME"] = home
  end

  def test_initialize_intuit
    Dir.mktmpdir do |path|
      Dir.chdir path do
        File.write "Manifest.txt", "FAQ.rdoc\nHistory.rdoc\nREADME.rdoc\n"
        File.write "README.rdoc", "= blah\n\nhome :: http://blah/"
        File.write "History.rdoc", "=== 1.0"

        assert_equal "History.rdoc", hoe.history_file
        assert_equal "README.rdoc", hoe.readme_file
        assert_equal %w[FAQ.rdoc History.rdoc README.rdoc],
                     hoe.spec.extra_rdoc_files
      end
    end
  end

  def test_initialize_intuit_ambiguous
    Dir.mktmpdir do |path|
      Dir.chdir path do
        File.write "Manifest.txt", "History.rdoc\nREADME.ja.rdoc\nREADME.rdoc\n"
        File.write "README.rdoc", "= blah\n\nhome :: http://blah/"
        File.write "README.ja.rdoc", "= blah\n\nhome :: http://blah/"
        File.write "History.rdoc", "=== 1.0"

        assert_equal "README.ja.rdoc", hoe(:skip_files).readme_file
      end
    end
  end

  def test_file_read_utf
    Tempfile.open "BOM" do |io|
      io.write "\xEF\xBB\xBFBOM"
      io.rewind

      content = File.read_utf io.path
      assert_equal "BOM", content

      if content.respond_to? :encoding then
        assert_equal Encoding::UTF_8, content.encoding
      end
    end
  end

  def test_parse_urls_ary
    ary  = ["* https://github.com/seattlerb/hoe",
            "* http://docs.seattlerb.org/hoe/",
            "* http://docs.seattlerb.org/hoe/Hoe.pdf",
            "* http://github.com/jbarnette/hoe-plugin-examples"].join "\n"

    exp = { "home" => "https://github.com/seattlerb/hoe" }
    err = /DEPRECATED: Please switch readme to hash format/

    assert_output "", err do
      assert_equal exp, hoe.parse_urls(ary)
    end
  end

  def test_parse_urls_hash
    hash = [
            "home  :: https://github.com/seattlerb/hoe",
            "rdoc  :: http://docs.seattlerb.org/hoe/",
            "doco  :: http://docs.seattlerb.org/hoe/Hoe.pdf",
            "other :: http://github.com/jbarnette/hoe-plugin-examples",
           ].join "\n"

    exp = {
      "home"  => "https://github.com/seattlerb/hoe",
      "rdoc"  => "http://docs.seattlerb.org/hoe/",
      "doco"  => "http://docs.seattlerb.org/hoe/Hoe.pdf",
      "other" => "http://github.com/jbarnette/hoe-plugin-examples",
    }

    assert_equal exp, hoe.parse_urls(hash)
  end

  def test_parse_mrww
    h = nil
    mrww_readme = <<~EOM
      = make
      = rake
      = work
      = well

      home :: https://github.com/seattlerb/makerakeworkwell
      rdoc :: http://docs.seattlerb.org/makerakeworkwell

      == DESCRIPTION:

      make/rake/work/well provides two simple modifications to rake that
      make working with file tasks cleaner, easier, and faster.
    EOM



    assert_silent do
      h = Hoe.spec "blah" do
        developer "author", "email"
        license "MIT"
        self.version      = "1.0"
        self.readme_file  = nil
        self.history_file = nil
        self.changes = true

        self.intuit_values mrww_readme
      end
    end

    desc = mrww_readme.lines[10..11].join.chomp
    urls = {
      "home" => "https://github.com/seattlerb/makerakeworkwell",
      "rdoc" => "http://docs.seattlerb.org/makerakeworkwell"
    }

    assert_equal desc, h.description
    assert_equal desc, h.summary
    assert_equal urls, h.urls
  end

  def test_intuit_values_should_be_silent_if_urls_are_already_set
    h = nil
    nokogiri_readme = <<~EOM
      ## Links
      
      * https://nokogiri.org
      * [Installation Help](https://nokogiri.org/tutorials/installing_nokogiri.html)
      * [Tutorials](https://nokogiri.org/tutorials/toc.html)
      * [Cheat Sheet](https://github.com/sparklemotion/nokogiri/wiki/Cheat-sheet)
      * [GitHub](https://github.com/sparklemotion/nokogiri)
      * [Mailing List](https://groups.google.com/group/nokogiri-talk)
      * [Chat/Gitter](https://gitter.im/sparklemotion/nokogiri)

    EOM

    exp = {
      "home" => "https://nokogiri.org",
      "bugs" => "https://github.com/sparklemotion/nokogiri/issues",
      "doco" => "https://nokogiri.org/rdoc/index.html",
      "clog" => "https://nokogiri.org/CHANGELOG.html",
      "code" => "https://github.com/sparklemotion/nokogiri",
    }

    assert_silent do
      h = Hoe.spec "blah" do
        developer "author", "email"
        license "MIT"

        self.urls = exp
        self.intuit_values nokogiri_readme
      end
    end

    assert_equal exp, h.urls
  end

  def test_intuit_values_should_be_silent_if_summary_description_and_homepage_are_set
    h = nil
    _readme = <<~EOM
      == this is readme

      == description
      this is a bogus description
    EOM

    assert_silent do
      h = Hoe.spec "blah" do
        developer "auther", "email"
        license "MIT"
        self.homepage = 'http://myhome'
        self.description = 'this is real description'
        self.summary = 'this is summary'
      end
    end

    assert_equal h.homepage , 'http://myhome'
    assert_equal h.description , 'this is real description'
    assert_equal h.summary , 'this is summary'
  end

  def test_metadata
    hash = [
            "home  :: https://github.com/seattlerb/hoe",
            "doco  :: http://docs.seattlerb.org/hoe/Hoe.pdf",
            "clog  :: https://github.com/seattlerb/hoe/master/History.rdoc",
            "bugs  :: https://github.com/seattlerb/hoe/issues",
            "code  :: https://github.com/seattlerb/hoe",
            "wiki  :: https://github.com/seattlerb/hoe/wiki",
            "mail  :: https://github.com/seattlerb/hoe/wiki#mailing_list",
           ].join "\n"

    exp = {
      "home" => "https://github.com/seattlerb/hoe",
      "doco" => "http://docs.seattlerb.org/hoe/Hoe.pdf",
      "clog" => "https://github.com/seattlerb/hoe/master/History.rdoc",
      "bugs" => "https://github.com/seattlerb/hoe/issues",
      "code" => "https://github.com/seattlerb/hoe",
      "wiki" => "https://github.com/seattlerb/hoe/wiki",
      "mail" => "https://github.com/seattlerb/hoe/wiki#mailing_list",
    }

    assert_equal exp, hoe.parse_urls(hash)
  end

  def test_possibly_better
    t = Gem::Specification::TODAY

    hoe = self.hoe do
      self.version = "1.2.3"
    end

    files = File.read("Manifest.txt").split(/\n/)

    spec = hoe.spec

    urls = {
      "home"  => "http://www.zenspider.com/projects/hoe.html",
      "code"  => "https://github.com/seattlerb/hoe",
      "bugs"  => "https://github.com/seattlerb/hoe/issues",
      "rdoc"  => "http://docs.seattlerb.org/hoe/",
      "doco"  => "http://docs.seattlerb.org/hoe/Hoe.pdf",
      "clog"  => "https://github.com/seattlerb/hoe/blob/master/History.rdoc",
      "other" => "http://github.com/jbarnette/hoe-plugin-examples",
    }

    assert_equal urls, hoe.urls

    text_files = files.grep(/(txt|rdoc)$/).reject { |f| f =~ /template/ }

    assert_equal "blah", spec.name
    assert_equal "1.2.3", spec.version.to_s
    assert_equal ">= 0", spec.required_rubygems_version.to_s

    assert_equal ["author"], spec.authors
    assert_equal t, spec.date
    assert_match(/Hoe.*Rakefiles/, spec.description)
    assert_equal ["email"], spec.email
    assert_equal ["sow"], spec.executables
    assert_equal text_files, spec.extra_rdoc_files
    assert_equal files.sort, spec.files.sort
    assert_equal urls["home"], spec.homepage
    assert_equal ["--main", "README.rdoc"], spec.rdoc_options
    assert_equal ["lib"], spec.require_paths
    assert_equal Gem::VERSION, spec.rubygems_version
    assert_match(/^Hoe.*Rakefiles$/, spec.summary)

    deps = spec.dependencies.sort_by(&:name)

    expected = [
      ["hoe",  :development, "~> #{Hoe::VERSION.sub(/\.\d+$/, "")}"],
      ["rdoc", :development, "< 7", ">= 4.0"],
    ]

    assert_equal expected, deps.map { |dep|
      dep_reqs = dep.requirement.to_s.split(/, /).sort
      [dep.name, dep.type, *dep_reqs]
    }
  end

  def test_no_license
    out, err = capture_io do
      assert_equal ["MIT"], self.hoe(:skip_license).spec.licenses
    end

    assert_equal "", out
    assert_match "Defaulting gemspec to MIT", err
  end

  def test_license
    spec = self.hoe.spec

    assert_equal %w[MIT], spec.licenses
  end

  def test_multiple_calls_to_license
    hoe = self.hoe :skip_license do
      license "MIT"
      license "GPL-2"
    end

    spec = hoe.spec

    assert_equal %w[MIT GPL-2], spec.licenses
  end

  def test_setting_licenses
    hoe = self.hoe :skip_license do
      self.licenses = ["MIT", "GPL-2"]
    end

    spec = hoe.spec

    assert_equal %w[MIT GPL-2], spec.licenses
  end

  def test_plugins
    before = Hoe.plugins.dup

    Hoe.plugin :first, :second
    assert_equal before + [:first, :second], Hoe.plugins

    Hoe.plugin :first, :second
    assert_equal before + [:first, :second], Hoe.plugins
  end

  def test_read_manifest
    expected = File.read_utf("Manifest.txt").split

    assert_equal expected, hoe.read_manifest
  end

  def test_rename
    # project, file_name, klass, test_klass = Hoe.normalize_names 'project_name'

    assert_equal %w[word      word     Word    TestWord],           Hoe.normalize_names("word")
    assert_equal %w[word      word     Word    TestWord],           Hoe.normalize_names("Word")
    assert_equal %w[two_words two_words TwoWords   TestTwoWords],       Hoe.normalize_names("TwoWords")
    assert_equal %w[two_words two_words TwoWords   TestTwoWords],       Hoe.normalize_names("twoWords")
    assert_equal %w[two-words two/words Two::Words TestTwo::TestWords], Hoe.normalize_names("two-words")
    assert_equal %w[two_words two_words TwoWords   TestTwoWords],       Hoe.normalize_names("two_words")
  end

  def test_nosudo
    hoe = self.hoe do
      def system cmd
        cmd
      end
    end

    assert_match(/^(sudo )?(j|maglev-)?gem.*/, hoe.install_gem("foo"))
    ENV["NOSUDO"] = "1"
    assert_match(/^(j|maglev-)?gem.*/, hoe.install_gem("foo"))
  ensure
    ENV.delete "NOSUDO"
  end

  def test_extensions
    Hoe.plugin :clean, :compiler
    Hoe.load_plugins

    hoe = nil

    capture_io do
      hoe = self.hoe do
        extension "a"
      end
    end

    assert_equal %w[ext/a/extconf.rb], hoe.spec.extensions

    @hoe = nil # clear cache

    capture_io do
      hoe = self.hoe do
        extension "a"
        extension "b"
      end
    end

    assert_equal %w[ext/a/extconf.rb ext/b/extconf.rb], hoe.spec.extensions
  end

  def test_with_config_default
    home = ENV["HOME"]
    Hoe.files = nil

    Dir.mktmpdir do |path|
      ENV["HOME"] = path

      hoeconfig = hoe.with_config { |config, _| config }

      assert_equal Hoe::DEFAULT_CONFIG, hoeconfig
    end
  ensure
    ENV["HOME"] = home
  end

  def test_with_config_overrides
    require "hoe/debug" # modifies Hoe::DEFAULT_CONFIG["exclude"]

    overrides = {
      "exclude" => Regexp.union( Hoe::DEFAULT_CONFIG["exclude"], /\.hg/ ),
      "plugins" => %w[tweedledee tweedledum],
    }
    overrides_rcfile = File.join(Dir.pwd, ".hoerc")

    home = ENV["HOME"]
    Hoe.files = nil

    Dir.mktmpdir do |path|
      ENV["HOME"] = path

      write_hoerc path, Hoe::DEFAULT_CONFIG

      open overrides_rcfile, File::CREAT|File::EXCL|File::WRONLY do |io|
        io.write YAML.dump( overrides )
      end

      hoeconfig = hoe.with_config { |config, _| config }

      assert_equal Hoe::DEFAULT_CONFIG.merge(overrides), hoeconfig
    end
  ensure
    File.delete overrides_rcfile if File.exist?( overrides_rcfile )
    ENV["HOME"] = home
  end
end
