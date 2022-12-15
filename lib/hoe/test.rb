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
  ##
  # Configuration for the supported test frameworks for test task.

  SUPPORTED_TEST_FRAMEWORKS = {
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
  # The test task created for this plugin.

  attr_accessor :test_task

  ##
  # Initialize variables for plugin.

  def initialize_test
    self.multiruby_skip ||= []
    self.testlib        ||= :minitest
    self.test_prelude   ||= nil
    self.test_task        = nil
  end

  ##
  # Define tasks for plugin.

  def define_test_tasks
    default_tasks = []

    task :test

    if File.directory? "test" then
      case testlib
      when :minitest then
        require "minitest/test_task" # in minitest 5.16+

        test_prelude = self.test_prelude
        self.test_task = Minitest::TestTask.create :test do |t|
          t.test_prelude = test_prelude
          t.libs.prepend Hoe.include_dirs.uniq
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

    desc "Run the default task(s)."
    task :default => default_tasks

    desc "Run ZenTest against the package."
    task :audit do
      libs = %w[lib test ext].join(File::PATH_SEPARATOR)
      sh "zentest -I=#{libs} #{spec.files.grep(/^(lib|test)/).join(" ")}"
    end
  end
end
