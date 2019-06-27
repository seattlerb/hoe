##
# Test plugin for hoe.
#
# === Tasks Provided:
#
# audit::              Run ZenTest against the package.
# default::            Run the default task(s).
# multi::              Run the test suite using multiruby.
# test::               Run the test suite.
# test_deps::          Show which test files fail when run alone.

module Hoe::Test
  def deprecate msg # :nodoc:
    where = caller_locations[1]

    warn "DEPRECATED: %s from %s" % [msg, where]
  end

  ##
  # Configuration for the supported test frameworks for test task.

  SUPPORTED_TEST_FRAMEWORKS = {
    :testunit => "test/unit",
    :minitest => "minitest/autorun",
    :none     => nil,
  }

  Hoe::DEFAULT_CONFIG["multiruby_skip"] = []

  ##
  # Optional: Array of incompatible versions for multiruby filtering.
  # Used as a regex.
  #
  # Can be defined both in .hoerc and in your hoe spec. Both will be
  # used.

  attr_accessor :multiruby_skip

  ##
  # Optional: What test library to require [default: :minitest]

  attr_accessor :testlib

  ##
  # Optional: Additional ruby to run before the test framework is loaded.

  attr_accessor :test_prelude

  ##
  # Optional: RSpec dirs. [default: %w(spec lib)]

  attr_accessor :rspec_dirs

  ##
  # Optional: RSpec options. [default: []]

  attr_accessor :rspec_options

  ##
  # Initialize variables for plugin.

  def initialize_test
    self.multiruby_skip ||= []
    self.testlib        ||= :minitest
    self.test_prelude   ||= nil
    self.rspec_dirs     ||= %w[spec lib]
    self.rspec_options  ||= []
  end

  ##
  # Define tasks for plugin.

  def define_test_tasks
    default_tasks = []

    task :test

    if File.directory? "test" then
      case testlib
      when :minitest then
        require "minitest/test_task" # currently in hoe, but will move

        Minitest::TestTask.create :test do |t|
          t.test_prelude = self.test_prelude
          t.libs += Hoe.include_dirs.uniq
        end
      when :testunit then
        desc "Run the test suite. Use FILTER or TESTOPTS to add flags/args."
        task :test do
          ruby make_test_cmd
        end

        desc "Print out the test command. Good for profiling and other tools."
        task :test_cmd do
          puts make_test_cmd
        end

        desc "Show which test files fail when run alone."
        task :test_deps do
          tests = Dir[*self.test_globs].uniq

          paths = %w[bin lib test].join(File::PATH_SEPARATOR)
          null_dev = Hoe::WINDOZE ? "> NUL 2>&1" : "> /dev/null 2>&1"

          tests.each do |test|
            unless system "ruby -I#{paths} #{test} #{null_dev}" then
              puts "Dependency Issues: #{test}"
            end
          end
        end

        if testlib == :minitest then
          desc "Show bottom 25 tests wrt time."
          task "test:slow" do
            sh "rake TESTOPTS=-v | sort -n -k2 -t= | tail -25"
          end
        end
      when :none then
        # do nothing
      else
        warn "Unsupported? Moving to Minitest::TestTask. Let me know if you use this!"
      end

      desc "Run the test suite using multiruby."
      task :multi do
        skip = with_config do |config, _|
          config["multiruby_skip"] + self.multiruby_skip
        end

        ENV["EXCLUDED_VERSIONS"] = skip.join(":")
        system "multiruby -S rake"
      end

      default_tasks << :test
    end

    if File.directory? "spec" then
      found = try_loading_rspec2 || try_loading_rspec1

      if found then
        default_tasks << :spec
      else
        warn "Found spec dir, but couldn't load rspec (1 or 2) task. skipping."
      end
    end

    desc "Run the default task(s)."
    task :default => default_tasks

    desc "Run ZenTest against the package."
    task :audit do
      libs = %w[lib test ext].join(File::PATH_SEPARATOR)
      sh "zentest -I=#{libs} #{spec.files.grep(/^(lib|test)/).join(" ")}"
    end
  end

  ##
  # Generate the test command-line.

  def make_test_cmd
    unless SUPPORTED_TEST_FRAMEWORKS.key?(testlib)
      raise "unsupported test framework #{testlib}"
    end

    deprecate "Moving to Minitest::TestTask. Let me know if you use this!"

    framework = SUPPORTED_TEST_FRAMEWORKS[testlib]

    tests = ["rubygems"]
    tests << framework if framework
    tests << test_globs.sort.map { |g| Dir.glob(g) }
    tests.flatten!
    tests.map! { |f| %(require "#{f}") }

    tests.insert 1, test_prelude if test_prelude

    filter = (ENV["FILTER"] || ENV["TESTOPTS"] || "").dup
    filter << " -n #{ENV["N"]}" if ENV["N"]
    filter << " -e #{ENV["X"]}" if ENV["X"]

    "#{Hoe::RUBY_FLAGS} -e '#{tests.join("; ")}' -- #{filter}"
  end

  ##
  # Attempt to load RSpec 2, returning true if successful

  def try_loading_rspec2
    deprecate "I want to drop this entirely. Let me know if you use this!"

    require "rspec/core/rake_task"

    desc "Run all specifications"
    RSpec::Core::RakeTask.new(:spec) do |t|
      t.rspec_opts = self.rspec_options
      t.rspec_opts << "-I#{self.rspec_dirs.join(":")}" unless
      rspec_dirs.empty?
    end

    true
  rescue LoadError => err
    warn "%p while trying to load RSpec 2: %s" % [ err.class, err.message ]
    false
  end

  ##
  # Attempt to load RSpec 1, returning true if successful

  def try_loading_rspec1
    deprecate "I want to drop this entirely. Let me know if you use this!"

    require "spec/rake/spectask"

    desc "Run all specifications"
    Spec::Rake::SpecTask.new(:spec) do |t|
      t.libs = self.rspec_dirs
      t.spec_opts = self.rspec_options
    end
    true
  rescue LoadError => err
    warn "%p while trying to load RSpec 1: %s" % [ err.class, err.message ]
    false
  end
end
