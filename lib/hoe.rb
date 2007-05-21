# -*- ruby -*-

require 'rubygems'
require 'rake'
require 'rake/contrib/sshpublisher'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'rake/testtask'
require 'rbconfig'
require 'rubyforge'

##
# hoe - a tool to help rake
#
# Hoe is a simple rake/rubygems helper for project Rakefiles. It
# generates all the usual tasks for projects including rdoc generation,
# testing, packaging, and deployment.
#
# == Using Hoe
#
# === Basics
#
# Use this as a minimal starting point:
#
#   require 'hoe'
#
#   Hoe.new("project_name", '1.0.0') do |p|
#     p.rubyforge_name = "rf_project"
#     # add other details here
#   end
#
#   # add other tasks here
#
# === Tasks Provided:
#
# * announce         - Generate email announcement file and post to rubyforge.
# * audit            - Run ZenTest against the package
# * check_manifest   - Verify the manifest
# * clean            - Clean up all the extras
# * config_hoe       - Create a fresh ~/.hoerc file
# * debug_gem        - Show information about the gem.
# * default          - Run the default tasks
# * docs             - Build the docs HTML Files
# * email            - Generate email announcement file.
# * gem              - Build the gem file only.
# * install          - Install the package. Uses PREFIX and RUBYLIB
# * install_gem      - Install the package as a gem
# * multi            - Run the test suite using multiruby
# * package          - Build all the packages
# * post_blog        - Post announcement to blog.
# * post_news        - Post announcement to rubyforge.
# * publish_docs     - Publish RDoc to RubyForge
# * release          - Package and upload the release to rubyforge.
# * ridocs           - Generate ri locally for testing
# * test             - Run the test suite. Use FILTER to add to the command line.
# * test_deps        - Show which test files fail when run alone.
# * uninstall        - Uninstall the package.
#
class Hoe
  VERSION = '1.2.1'

  ruby_prefix = Config::CONFIG['prefix']
  sitelibdir = Config::CONFIG['sitelibdir']

  ##
  # Used to specify a custom install location (for rake install).

  PREFIX = ENV['PREFIX'] || ruby_prefix

  ##
  # Used to add extra flags to RUBY_FLAGS.

  RUBY_DEBUG = ENV['RUBY_DEBUG']

  default_ruby_flags = "-w -I#{%w(lib ext bin test).join(File::PATH_SEPARATOR)}" +
    (RUBY_DEBUG ? " #{RUBY_DEBUG}" : '')

  ##
  # Used to specify flags to ruby [has smart default].

  RUBY_FLAGS = ENV['RUBY_FLAGS'] || default_ruby_flags

  ##
  # Used to add flags to test_unit (e.g., -n test_borked).

  FILTER = ENV['FILTER'] # for tests (eg FILTER="-n test_blah")

  # :stopdoc:

  RUBYLIB = if PREFIX == ruby_prefix then
              sitelibdir
            else
              File.join(PREFIX, sitelibdir[ruby_prefix.size..-1])
            end

  WINDOZE = /win32/ =~ RUBY_PLATFORM unless defined? WINDOZE

  DIFF = if WINDOZE
           'diff.exe'
         else
           if system("gdiff", __FILE__, __FILE__)
             'gdiff' # solaris and kin suck
           else
             'diff'
           end
         end unless defined? DIFF

  # :startdoc:

  ##
  # *Recommended*: The author(s) of the package. (can be array)
  # Really. Set this or we'll tease you.

  attr_accessor :author

  ##
  # Populated automatically from the manifest. List of executables.

  attr_accessor :bin_files # :nodoc:

  ##
  # *Recommended*: A description of the release's latest changes.

  attr_accessor :changes

  ##
  # Optional: An array of file patterns to delete on clean.

  attr_accessor :clean_globs

  ##
  # *Recommended*: A description of the project.

  attr_accessor :description

  ##
  # *Recommended*: The author's email address(es). (can be array)

  attr_accessor :email

  ##
  # Optional: An array of rubygem dependencies.

  attr_accessor :extra_deps

  ##
  # Populated automatically from the manifest. List of library files.

  attr_accessor :lib_files # :nodoc:

  ##
  # *MANDATORY*: The name of the release.

  attr_accessor :name

  ##
  # Optional: Should package create a tarball? [default: true]

  attr_accessor :need_tar

  ##
  # Optional: Should package create a zipfile? [default: false]

  attr_accessor :need_zip

  ##
  # Optional: A regexp to match documentation files against the manifest.

  attr_accessor :rdoc_pattern

  ##
  # Optional: Name of RDoc destination directory on Rubyforge. [default: +name+]

  attr_accessor :remote_rdoc_dir

  ##
  # Optional: Flags for RDoc rsync. [default: "-av --delete"]

  attr_accessor :rsync_args

  ##
  # Optional: The name of the rubyforge project. [default: name.downcase]

  attr_accessor :rubyforge_name

  ##
  # The Gem::Specification.

  attr_accessor :spec # :nodoc:

  ##
  # Optional: A hash of extra values to set in the gemspec. Value may be a proc.

  attr_accessor :spec_extras

  ##
  # *Recommended*: A short summary of the project.

  attr_accessor :summary

  ##
  # Populated automatically from the manifest. List of tests.

  attr_accessor :test_files # :nodoc:

  ##
  # Optional: An array of test file patterns [default: test/**/test_*.rb]

  attr_accessor :test_globs

  ##
  # *Recommended*: The url(s) of the project. (can be array)

  attr_accessor :url

  ##
  # *MANDATORY*: The version. Don't hardcode! use a constant in the project.

  attr_accessor :version

  def initialize(name, version) # :nodoc:
    self.name = name
    self.version = version

    # Defaults
    self.author = "Ryan Davis"
    self.changes = "The author was too lazy to write a changeset"
    self.clean_globs = %w(diff diff.txt email.txt ri *.gem **/*~)
    self.description = "The author was too lazy to write a description"
    self.email = "ryand-ruby@zenspider.com"
    self.extra_deps = []
    self.need_tar = true
    self.need_zip = false
    self.rdoc_pattern = /^(lib|bin)|txt$/
    self.remote_rdoc_dir = name
    self.rsync_args = '-av --delete'
    self.rubyforge_name = name.downcase
    self.spec_extras = {}
    self.summary = "The author was too lazy to write a summary"
    self.test_globs = ['test/**/test_*.rb']
    self.url = "http://www.zenspider.com/ZSS/Products/#{name}/"

    yield self if block_given?

    hoe_deps = {
      'rake' => ">= #{RAKEVERSION}",
      'rubyforge' => ">= #{::RubyForge::VERSION}",
    }

    self.extra_deps = Array(extra_deps) # just in case user used = instead of <<
    self.extra_deps = [extra_deps] unless
      extra_deps.empty? or Array === extra_deps.first
    if name == 'hoe' then
      hoe_deps.each do |pkg, version|
        extra_deps << [pkg, version]
      end
    else
      extra_deps << ['hoe', ">= #{VERSION}"] unless hoe_deps.has_key? name
    end

    define_tasks
  end

  def define_tasks # :nodoc:
    desc 'Run the default tasks'
    task :default => :test

    desc 'Run the test suite. Use FILTER to add to the command line.'
    task :test do
      run_tests
    end

    desc 'Show which test files fail when run alone.'
    task :test_deps do
      tests = Dir["test/**/test_*.rb"]  +  Dir["test/**/*_test.rb"]

      tests.each do |test|
        if not system "ruby -Ibin:lib:test #{test} &> /dev/null" then
          puts "Dependency Issues: #{test}"
        end
      end
    end

    desc 'Run the test suite using multiruby'
    task :multi do
      run_tests :multi
    end

    ############################################################
    # Packaging and Installing

    self.spec = Gem::Specification.new do |s|
      s.name = name
      s.version = version
      s.summary = summary
      case author
      when Array
        s.authors = author
      else
        s.author = author
      end
      s.email = email
      s.homepage = Array(url).first
      s.rubyforge_project = rubyforge_name

      s.description = description

      extra_deps.each do |dep|
        s.add_dependency(*dep)
      end

      s.files = File.read("Manifest.txt").delete("\r").split(/\n/)
      s.executables = s.files.grep(/^bin/) { |f| File.basename(f) }

      s.bindir = "bin"
      dirs = Dir['{lib,ext}']
      s.require_paths = dirs unless dirs.empty?

      s.rdoc_options = ['--main', 'README.txt']
      s.extra_rdoc_files = s.files.grep(/txt$/)
      s.has_rdoc = true

      if test ?f, "test/test_all.rb" then
        s.test_file = "test/test_all.rb"
      else
        s.test_files = Dir[*test_globs]
      end

      # Do any extra stuff the user wants
      spec_extras.each do |msg, val|
        case val
        when Proc
          val.call(s.send(msg))
        else
          s.send "#{msg}=", val
        end
      end
    end

    desc 'Show information about the gem.'
    task :debug_gem do
      puts spec.to_ruby
    end

    self.lib_files = spec.files.grep(/^(lib|ext)/)
    self.bin_files = spec.files.grep(/^bin/)
    self.test_files = spec.files.grep(/^test/)

    Rake::GemPackageTask.new spec do |pkg|
      pkg.need_tar = @need_tar
      pkg.need_zip = @need_zip
    end

    desc 'Install the package. Uses PREFIX and RUBYLIB'
    task :install do
      [
       [lib_files + test_files, RUBYLIB, 0444],
       [bin_files, File.join(PREFIX, 'bin'), 0555]
      ].each do |files, dest, mode|
        FileUtils.mkdir_p dest unless test ?d, dest
        files.each do |file|
          install file, dest, :mode => mode
        end
      end
    end

    desc 'Install the package as a gem'
    task :install_gem => [:clean, :package] do
      sh "sudo gem install pkg/*.gem"
    end

    desc 'Uninstall the package.'
    task :uninstall do
      Dir.chdir RUBYLIB do
        rm_f((lib_files + test_files).map { |f| File.basename f })
      end
      Dir.chdir File.join(PREFIX, 'bin') do
        rm_f bin_files.map { |f| File.basename f }
      end
    end

    desc 'Package and upload the release to rubyforge.'
    task :release => [:clean, :package] do |t|
      v = ENV["VERSION"] or abort "Must supply VERSION=x.y.z"
      abort "Versions don't match #{v} vs #{version}" if v != version
      pkg = "pkg/#{name}-#{version}"

      if $DEBUG then
        puts "release_id = rf.add_release #{rubyforge_name.inspect}, #{name.inspect}, #{version.inspect}, \"#{pkg}.tgz\""
        puts "rf.add_file #{rubyforge_name.inspect}, #{name.inspect}, release_id, \"#{pkg}.gem\""
      end

      rf = RubyForge.new
      puts "Logging in"
      rf.login

      c = rf.userconfig
      c["release_notes"] = description if description
      c["release_changes"] = changes if changes
      c["preformatted"] = true

      files = [(@need_tar ? "#{pkg}.tgz" : nil),
               (@need_zip ? "#{pkg}.zip" : nil),
               "#{pkg}.gem"].compact

      puts "Releasing #{name} v. #{version}"
      rf.add_release rubyforge_name, name, version, *files
    end

    ############################################################
    # Doco

    Rake::RDocTask.new(:docs) do |rd|
      rd.main = "README.txt"
      rd.options << '-d' if RUBY_PLATFORM !~ /win32/ and `which dot` =~ /\/dot/
      rd.rdoc_dir = 'doc'
      files = spec.files.grep(rdoc_pattern)
      files -= ['Manifest.txt']
      rd.rdoc_files.push(*files)

      title = "#{name}-#{version} Documentation"
      title = "#{rubyforge_name}'s " + title if rubyforge_name != title

      rd.options << "-t #{title}"
    end

    desc "Generate ri locally for testing"
    task :ridocs => :clean do
      sh %q{ rdoc --ri -o ri . }
    end

    desc "Publish RDoc to RubyForge"
    task :publish_docs => [:clean, :docs] do
      config = YAML.load(File.read(File.expand_path("~/.rubyforge/user-config.yml")))
      host = "#{config["username"]}@rubyforge.org"

      remote_dir = "/var/www/gforge-projects/#{rubyforge_name}/#{remote_rdoc_dir}"
      local_dir = 'doc'

      sh %{rsync #{rsync_args} #{local_dir}/ #{host}:#{remote_dir}}
    end

    # no doco for this one
    task :publish_on_announce do
      with_config do |rc, path|
        if rc["publish_on_announce"] then
          Rake::Task['publish_docs'].invoke
        end
      end
    end

    ############################################################
    # Misc/Maintenance:

    def with_config(create=false) # :nodoc:
      require 'yaml'
      rc = File.expand_path("~/.hoerc")

      unless create then
        if test ?f, rc then
          config = YAML.load_file(rc)
          yield(config, rc)
        end
      else
        unless test ?f, rc then
          yield(rc)
        end
      end
    end

    desc 'Run ZenTest against the package'
    task :audit do
      libs = %w(lib test ext).join(File::PATH_SEPARATOR)
      sh "zentest -I=#{libs} #{spec.files.grep(/^(lib|test)/).join(' ')}"
    end

    desc 'Clean up all the extras'
    task :clean => [ :clobber_docs, :clobber_package ] do
      clean_globs.each do |pattern|
        files = Dir[pattern]
        rm_rf files unless files.empty?
      end
    end

    desc 'Create a fresh ~/.hoerc file'
    task :config_hoe do
      with_config(:create) do |rc, path|
        blog = {
          "publish_on_announce" => false,
          "blogs" => [ {
                         "user" => "user",
                         "url" => "url",
                         "extra_headers" => {
                           "mt_convert_breaks" => "markdown"
                         },
                         "blog_id" => "blog_id",
                         "password"=>"password",
                       } ],
        }
        File.open(rc, "w") do |f|
          YAML.dump(blog, f)
        end
      end

      with_config do |rc, path|
        editor = ENV['EDITOR'] || 'vi'
        system "#{editor} #{path}"
      end
    end

    desc 'Generate email announcement file.'
    task :email do
      require 'rubyforge'
      subject, title, body, urls = announcement

      File.open("email.txt", "w") do |mail|
        mail.puts "Subject: [ANN] #{subject}"
        mail.puts
        mail.puts title
        mail.puts
        mail.puts urls
        mail.puts
        mail.puts body
        mail.puts
        mail.puts urls
      end
      puts "Created email.txt"
    end

    desc 'Post announcement to blog.'
    task :post_blog do
      require 'xmlrpc/client'

      with_config do |config, path|
        subject, title, body, urls = announcement

        body += "\n\n#{urls}"

        config['blogs'].each do |site|
          server = XMLRPC::Client.new2(site['url'])
          content = site['extra_headers'].merge(:title => title,
                                                :description => body)
          result = server.call('metaWeblog.newPost',
                               site['blog_id'],
                               site['user'],
                               site['password'],
                               content,
                               true)
        end
      end
    end

    desc 'Post announcement to rubyforge.'
    task :post_news do
      require 'rubyforge'
      subject, title, body, urls = announcement

      rf = RubyForge.new
      rf.login
      rf.post_news(rubyforge_name, subject, "#{title}\n\n#{body}")
      puts "Posted to rubyforge"
    end

    desc 'Generate email announcement file and post to rubyforge.'
    task :announce => [:email, :post_news, :post_blog, :publish_on_announce ]

    desc "Verify the manifest"
    task :check_manifest => :clean do
      f = "Manifest.tmp"
      require 'find'
      files = []
      Find.find '.' do |path|
        next unless File.file? path
        next if path =~ /\.svn|tmp$|CVS/
        files << path[2..-1]
      end
      files = files.sort.join "\n"
      File.open f, 'w' do |fp| fp.puts files end
      system "#{DIFF} -du Manifest.txt #{f}"
      rm f
    end

  end # end define

  def announcement # :nodoc:
    changes = self.changes.rdoc_to_markdown

    subject = "#{name} #{version} Released"
    title = "#{name} version #{version} has been released!"
    body = "#{description}\n\nChanges:\n\n#{changes}".rdoc_to_markdown
    urls = Array(url).map { |s| "* <#{s.strip.rdoc_to_markdown}>" }.join("\n")

    return subject, title, body, urls
  end

  def run_tests(multi=false) # :nodoc:
    msg = multi ? :sh : :ruby
    cmd = if test ?f, 'test/test_all.rb' then
            "#{RUBY_FLAGS} test/test_all.rb #{FILTER}"
          else
            tests = test_globs.map { |g| Dir.glob(g) }.flatten << 'test/unit'
            tests.map! {|f| %Q(require "#{f}")}
            "#{RUBY_FLAGS} -e '#{tests.join("; ")}' #{FILTER}"
          end
    cmd = "multiruby #{cmd}" if multi
    send msg, cmd
  end

  ##
  # Reads a file at +path+ and spits out an array of the +paragraphs+ specified.
  #
  #   changes = p.paragraphs_of('History.txt', 0..1).join("\n\n")
  #   summary, *description = p.paragraphs_of('README.txt', 3, 3..8)

  def paragraphs_of(path, *paragraphs)
    File.read(path).delete("\r").split(/\n\n+/).values_at(*paragraphs)
  end
end

# :enddoc:

class ::Rake::SshDirPublisher # :nodoc:
  attr_reader :host, :remote_dir, :local_dir
end

class String
  def rdoc_to_markdown
    self.gsub(/^mailto:/, '').gsub(/^(=+)/) { "#" * $1.size }
  end
end

if $0 == __FILE__ then
  out = `rake -T | egrep -v "redocs|repackage|clobber|trunk"`
  puts out.gsub(/\#/, '-').gsub(/^rake /, '# * ')
end
