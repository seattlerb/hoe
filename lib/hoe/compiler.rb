##
# rake-compiler plugin for hoe c-extensions.

module Hoe::Compiler
  def initialize_compiler
    extra_dev_deps << ["rake-compiler", "~> 0.7"]

    self.spec_extras = { :extensions => ["ext/#{self.name}/extconf.rb"] }
  end

  ##
  # Define tasks for compiler plugin.

  def define_compiler_tasks
    require "rake/extensiontask"

    Rake::ExtensionTask.new self.name, spec do |ext|
      ext.lib_dir = File.join(*["lib", self.name, ENV["FAT_DIR"]].compact)
    end
  end
end
