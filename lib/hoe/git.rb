class Hoe # :nodoc:

  ##
  # This module is a Hoe plugin. You can set its attributes in your
  # Rakefile Hoe spec, like this:
  #
  #    Hoe.plugin :git
  #
  #    Hoe.spec "myproj" do
  #      self.git_release_tag_prefix  = "REL_"
  #      self.git_remotes            << "myremote"
  #    end
  #
  #
  # === Tasks
  #
  # git:changelog:: Print the current changelog.
  # git:manifest::  Update the manifest with Git's file list.
  # git:tag::       Create and push a tag.

  module Git

    ##
    # What do you want at the front of your release tags?
    # [default: <tt>"v"</tt>]

    attr_accessor :git_release_tag_prefix

    ##
    # Which remotes do you want to push tags, etc. to?
    # [default: <tt>%w[ origin ]</tt>]

    attr_accessor :git_remotes

    attr_accessor :git_changes # :nodoc:

    def initialize_git # :nodoc:
      self.git_release_tag_prefix = "v"
      self.git_remotes            = %w[ origin ]
    end

    def define_git_tasks # :nodoc:
      return unless File.exist? ".git"

      desc "Print the current changelog."
      task "git:changelog" do
        tag   = ENV["FROM"] || git_tags.last
        range = [tag, "HEAD"].compact.join ".."

        changes = `git log #{range} --format="tformat:%B|||%aN|||%aE|||"`
          .split("|||")
          .each_slice(3)
          .map { |msg, author, email|
            msg.lines(chomp: true).reject(&:empty?)
          }
          .flatten

        next if changes.empty?

        self.git_changes = Hash.new { |h, k| h[k] = [] }

        codes = {
          "!" => :major,
          "+" => :minor,
          "*" => :minor,
          "-" => :bug,
          "?" => :unknown,
        }

        codes_re = Regexp.escape codes.keys.join

        changes.each do |change|
          if change =~ /^\s*([#{codes_re}])\s*(.*)/ then
            code, line = codes[$1], $2
          else
            code, line = codes["?"], change.chomp
          end

          git_changes[code] << line
        end

        now = Time.new.strftime "%Y-%m-%d"

        puts "=== #{ENV["VERSION"] || "NEXT"} / #{now}"
        puts
        changelog_section :major
        changelog_section :minor
        changelog_section :bug
        changelog_section :unknown
        puts
      end

      desc "Update the manifest with Git's file list. Use Hoe's excludes."
      task "git:manifest" do
        with_config do |config, _|
          files = `git ls-files`
            .lines(chomp:true)
            .grep_v(config["exclude"])

          File.write "Manifest.txt", files.sort.join("\n")
        end
      end

      desc "Create and push a TAG " +
           "(default #{git_release_tag_prefix}#{version})."

      task "git:tag" do
        tag = ENV["TAG"]
        ver = ENV["VERSION"] || version
        pre = ENV["PRERELEASE"] || ENV["PRE"]
        ver += ".#{pre}" if pre
        tag ||= "#{git_release_tag_prefix}#{ver}"

        git_tag_and_push tag
      end

      task "git:tags" do
        p git_tags
      end

      task :release_sanity do
        unless ENV["DIRTY"] or `git status --porcelain`.empty?
          abort "Won't release: Dirty index or untracked files present!"
        end
      end

      task :release_to => "git:tag"
    end

    ##
    # Generate a tag and push it to all remotes.

    def git_tag_and_push tag
      msg = "Tagging #{tag}."

      flags = " -s" unless `git config --get user.signingkey`.empty?

      sh %Q(git tag#{flags} -f #{tag} -m "#{msg}")
      git_remotes.each { |remote| sh "git push -f #{remote} tag #{tag}" }
    end

    ##
    # Return all git tags massaged down to readable versions.

    def git_tags
      flags  = %w[--date-order
                  --reverse
                  --simplify-by-decoration
                  --pretty=format:%H].join " "
      shas = `git log #{flags}`.lines(chomp: true)

      `git name-rev --tags #{shas.join " "}`
        .lines
        .map { |s| s[/tags\/(#{git_release_tag_prefix}.+)/, 1] }
        .compact
        .map { |s| s.sub(/\^0$/, "") } # v1.2.3^0 -> v1.2.3 (why?)
        .grep(%r{^#{git_release_tag_prefix}}) # TODO: remove?
    end

    ##
    # Generate and print a changelog section based on the +code+.

    def changelog_section code
      name = +{
        :major   => "major enhancement",
        :minor   => "minor enhancement",
        :bug     => "bug fix",
        :unknown => "unknown",
      }[code]

      changes = git_changes[code]
      count = changes.size
      name += "s" if count > 1
      name.sub!(/fixs/, "fixes")

      return if count < 1

      puts "* #{count} #{name}:"
      puts
      changes.sort.each do |line|
        puts "  * #{line}"
      end
      puts
    end
  end
end
