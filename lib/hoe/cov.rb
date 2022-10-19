##
# Coverage plugin for hoe. Uses simplecov.
#
# === Tasks Provided:
#
# cov:: Analyze code coverage with tests using simplecov.

module Hoe::Cov

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
      test_task.test_prelude = "require \"simplecov\"; SimpleCov.start"

      Rake::Task[:test].invoke
    end
  rescue LoadError
    warn "simplecov not found"
  end
end
