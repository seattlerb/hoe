##
# Coverage plugin for hoe. Uses simplecov.
#
# === Tasks Provided:
#
# cov:: Analyze code coverage with tests using simplecov.

module Hoe::Cov

  ##
  # Directories to filter out from coverage.
  #
  # The default = tmp:test

  attr_accessor :cov_filter

  ##
  # Set to true to enable branch level coverage reporting.
  #
  # The default = false

  attr_accessor :cov_branches

  def initialize_cov # :nodoc:
    self.cov_filter = %w[tmp test]
    self.cov_branches = nil
  end

  ##
  # Activate the cov dependencies.

  def activate_cov_deps
    dependency "simplecov", "~> 0.21", :development
  end

  ##
  # Define tasks for plugin.

  def define_cov_tasks
    task :isolate # ensure it exists

    self.clean_globs << "coverage"

    desc "Run tests and analyze code coverage"
    task :cov => :isolate do
      extra = cov_branches && "; enable_coverage :branch"
      test_task.test_prelude =
        %(require "simplecov"; SimpleCov.start { add_filter %p%s }) % [cov_filter, extra]

      Rake::Task[:test].invoke
    end
  rescue LoadError
    warn "simplecov not found"
  end
end
