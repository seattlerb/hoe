begin
  gem 'rdoc'
rescue Gem::LoadError
end

begin
  require 'rdoc/task'
rescue LoadError
  require 'rake/rdoctask'
end

##
# Publish plugin for hoe.
#
# === Tasks Provided:
#
# announce::           Create news email file and post to rubyforge.
# debug_email::        Generate email announcement file.
# post_blog::          Post announcement to blog.
# post_news::          Post announcement to rubyforge.
# publish_docs::       Publish RDoc to RubyForge.
# ridocs::             Generate ri locally for testing.
#
# === Extra Configuration Options:
#
# publish_on_announce:: Run +publish_docs+ when you run +release+.
# blogs::               An array of hashes of blog settings.

module Hoe::Publish
  ##
  # Optional: An array of the project's blog categories. Defaults to project
  # name.

  attr_accessor :blog_categories

  ##
  # Optional: Name of destination directory for RDoc generated files.
  # [default: doc]

  attr_accessor :local_rdoc_dir

  ##
  # Optional: Should RDoc and ri generation tasks be defined? [default: true]
  #
  # Allows you to define custom RDoc tasks then use the publish_rdoc task to
  # upload them all.  See also local_rdoc_dir

  attr_accessor :need_rdoc

  ##
  # Optional: An array of remote (rsync) paths to copy rdoc to.
  #
  # eg:
  #
  #     rdoc_locations << "user@server:Sites/rdoc/#{remote_rdoc_dir}"

  attr_accessor :rdoc_locations

  ##
  # Optional: Name of RDoc destination directory on Rubyforge. [default: +name+]

  attr_accessor :remote_rdoc_dir

  ##
  # Optional: Flags for RDoc rsync. [default: "-av --delete"]

  attr_accessor :rsync_args

  Hoe::DEFAULT_CONFIG["publish_on_announce"] = true
  Hoe::DEFAULT_CONFIG["blogs"] = [
                                  {
                                    "user"     => "user",
                                    "password" => "password",
                                    "url"      => "url",
                                    "blog_id"  => "blog_id",
                                    "extra_headers" => {
                                      "mt_convert_breaks" => "markdown"
                                    },
                                  }
                                 ]

  ##
  # Initialize variables for plugin.

  def initialize_publish
    self.blog_categories ||= [self.name]
    self.local_rdoc_dir  ||= 'doc'
    self.need_rdoc       ||= true
    self.rdoc_locations  ||= []
    self.remote_rdoc_dir ||= self.name
    self.rsync_args      ||= '-av --delete'
  end

  ##
  # Define tasks for plugin.

  def define_publish_tasks
    if need_rdoc then
      Rake::RDocTask.new(:docs) do |rd|
        rd.main = readme_file
        rd.options << '-d' if (`which dot` =~ /\/dot/) unless
          ENV['NODOT'] || Hoe::WINDOZE
        rd.rdoc_dir = local_rdoc_dir

        rd.rdoc_files += spec.require_paths
        rd.rdoc_files += spec.extra_rdoc_files

        title = spec.rdoc_options.grep(/^(-t|--title)=?$/).first

        if title then
          rd.options << title

          unless title =~ /\=/ then # for ['-t', 'title here']
            title_index = spec.rdoc_options.index(title)
            rd.options << spec.rdoc_options[title_index + 1]
          end
        else
          title = "#{name}-#{version} Documentation"
          title = "#{rubyforge_name}'s " + title if rubyforge_name != name
          rd.options << '--title' << title
        end
      end

      desc 'Generate ri locally for testing.'
      task :ridocs => :clean do
        sh %q{ rdoc --ri -o ri . }
      end
    end

    desc "Publish RDoc to wherever you want."
    task :publish_docs => [:clean, :docs] do
      warn "no rdoc_location values" if rdoc_locations.empty?
      self.rdoc_locations.each do |dest|
        sh %{rsync #{rsync_args} #{local_rdoc_dir}/ #{dest}}
      end
    end

    # no doco for this one
    task :publish_on_announce do
      with_config do |config, _|
        Rake::Task['publish_docs'].invoke if config["publish_on_announce"]
      end
    end

    desc 'Generate email announcement file.'
    task :debug_email do
      puts generate_email
    end

    desc 'Post announcement to blog.'
    task :post_blog do
      require 'xmlrpc/client'

      with_config do |config, path|
        break unless config['blogs']

        subject, title, body, urls = announcement
        body += "\n\n#{urls}"

        config['blogs'].each do |site|
          server = XMLRPC::Client.new2(site['url'])
          content = site['extra_headers'].merge(:title => title,
                                                :description => body,
                                                :categories => blog_categories)

          result = server.call('metaWeblog.newPost',
                               site['blog_id'],
                               site['user'],
                               site['password'],
                               content,
                               true)
        end
      end
    end

    desc 'Announce your release.'
    task :announce => [:post_blog, :publish_on_announce ]
  end

  def generate_email full = nil
    require 'time'

    abort "No email 'to' entry. Run `rake config_hoe` to fix." unless
      !full || email_to

    from_name, from_email      = author.first, email.first
    subject, title, body, urls = announcement

    [
     full && "From: #{from_name} <#{from_email}>",
     full && "To: #{email_to.join(", ")}",
     full && "Date: #{Time.now.rfc2822}",
     "Subject: [ANN] #{subject}",
     "", title,
     "", urls,
     "", body,
    ].compact.join("\n")
  end

  def announcement # :nodoc:
    changes = self.changes.rdoc_to_markdown
    subject = "#{name} #{version} Released"
    title   = "#{name} version #{version} has been released!"
    body    = "#{description}\n\nChanges:\n\n#{changes}".rdoc_to_markdown
    urls    = Array(url).map { |s| "* <#{s.strip.rdoc_to_markdown}>" }.join("\n")

    return subject, title, body, urls
  end
end

class ::Rake::SshDirPublisher # :nodoc:
  attr_reader :host, :remote_dir, :local_dir
end

class String
  ##
  # Very basic munge from rdoc to markdown format.

  def rdoc_to_markdown
    self.gsub(/^mailto:/, '').gsub(/^(=+)/) { "#" * $1.size }
  end
end
