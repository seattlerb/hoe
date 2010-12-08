##
# Racc plugin for hoe.
#
# === Tasks Provided:
#
# lexer            :: Generate lexers for all .rex files in your Manifest.txt.
# parser           :: Generate parsers for all .y files in your Manifest.txt.
# .y   -> .rb rule :: Generate a parser using racc.
# .rex -> .rb rule :: Generate a lexer using rexical.

module Hoe::Racc

  ##
  # Optional: Defines what tasks need to generate parsers/lexers first.

  attr_accessor :racc_tasks

  ##
  # Initialize variables for racc plugin.

  def initialize_racc
    self.racc_tasks = [:multi, :test, :check_manifest]

    extra_dev_deps << ['racc', '~> 1.4.7']
  end

  ##
  # Define tasks for racc plugin

  def define_racc_tasks
    racc_files   = self.spec.files.find_all { |f| f =~ /\.y$/ }
    rex_files    = self.spec.files.find_all { |f| f =~ /\.rex$/ }

    parser_files = racc_files.map { |f| f.sub(/\.y$/, ".rb") }
    lexer_files  = rex_files.map  { |f| f.sub(/\.rex$/, ".rb") }

    rule ".rb" => ".y" do |t|
      # -v = verbose
      # -t = debugging parser ~4% reduction in speed -- keep for now
      # -l = no-line-convert
      begin
        # TODO: variable for flags
        sh "racc -v -t -l -o #{t.name} #{t.source}"
      rescue
        abort "need racc, sudo gem install racc"
      end
    end

    rule ".rb" => ".rex" do |t|
      begin
        sh "rex --independent -o #{t.name} #{t.source}"
      rescue
        abort "need rexical, sudo gem install rexical"
      end
    end

    desc "build the parser" unless parser_files.empty?
    task :parser

    desc "build the lexer" unless lexer_files.empty?
    task :lexer

    task :parser => parser_files
    task :lexer  => lexer_files

    racc_tasks.each do |t|
      task t => [:parser, :lexer]
    end

    task :clobber do
      rm_rf parser_files + lexer_files
    end
  end
end
