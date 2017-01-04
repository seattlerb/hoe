##
# rake-compiler plugin for hoe c-extensions.
#
# This plugin is for extconf.rb based projects that want to use
# rake-compiler to deal with packaging binary gems. It expects a
# standard extconf setup, namely that your extconf.rb and c source is
# located in: ext/project-name.
#
# Look at nokogiri for a good example of how to use this.
#
# === Tasks Provided:
#
# compile::     Compile your c-extension.

module Hoe::Compiler

  ##
  # Optional: Defines what tasks need to be compile first. [default: test]

  attr_accessor :compile_tasks

  ##
  # Initialize variables for compiler plugin.

  def initialize_compiler
    self.compile_tasks = [:multi, :test, :check_manifest]
  end

  ##
  # Activate the rake-compiler dependencies.

  def activate_compiler_deps
    dependency "rake-compiler", "~> 1.0", :development

    gem "rake-compiler", "~> 1.0"
  rescue LoadError
    warn "Couldn't load rake-compiler. Skipping. Run `rake newb` to fix."
  end

  def extension name
    @extensions ||= []
    @extensions << name
    spec_extras[:extensions] = @extensions.map { |n| "ext/#{n}/extconf.rb" }
  end

  ##
  # Define tasks for compiler plugin.

  def define_compiler_tasks
    require "rake/extensiontask"

    @extensions.each do |name|
      clean_globs << "lib/#{name}/*.{so,bundle,dll}"

      Rake::ExtensionTask.new name, spec do |ext|
        ext.lib_dir = File.join(*["lib", name.to_s, ENV["FAT_DIR"]].compact)
      end
    end

    compile_tasks.each do |t|
      task t => :compile
    end
  rescue LoadError
    warn "Couldn't load rake-compiler. Skipping. Run `rake newb` to fix."
  end
end
