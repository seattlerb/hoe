require "rake"

##
# Gemcutter plugin for hoe.
#
# === Extra Configuration Options:
#
# otp_command:: Shell command to run to populate GEM_HOST_OTP_CODE.

module Hoe::Gemcutter
  include Rake::DSL if defined?(Rake::DSL)

  Hoe::DEFAULT_CONFIG["otp_command"] = false

  ##
  # Push gems to server.

  def gem_push gems
    with_config do |config, _|
      otp_command = config["otp_command"]

      ENV["GEM_HOST_OTP_CODE"] = `#{otp_command}`.chomp if otp_command
    end

    gems.each do |g|
      sh Gem.ruby, "-S", "gem", "push", g
    end
  end

  ##
  # Define release_to_gemcutter and attach it to the release task.

  def define_gemcutter_tasks
    desc "Push gem to gemcutter."
    task :release_to_gemcutter => [:clean, :package, :release_sanity] do
      pkg   = "pkg/#{spec.name}-#{spec.version}"
      gems  = Dir["#{pkg}*.gem"]

      gem_push gems
    end

    task :release_to => :release_to_gemcutter
  end
end unless defined? Hoe::Gemcutter
