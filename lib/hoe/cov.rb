##
# Coverage plugin for hoe. Uses simplecov.
#
# === Tasks Provided:
#
# cov:: Analyze code coverage with tests using simplecov.

module Hoe::Cov

  ##
  # Directories to filter out from coverage.

  attr_accessor :cov_filter

  def initialize_cov # :nodoc:
    self.cov_filter = %w[tmp test]
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
      test_task.test_prelude =
        %(require "simplecov"; SimpleCov.start { add_filter %p }) % [cov_filter]

      Rake::Task[:test].invoke
    end
  rescue LoadError
    warn "simplecov not found"
  end
end
