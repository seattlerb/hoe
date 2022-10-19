require "minitest/autorun"
require "hoe"
require_relative "../lib/hoe/gemcutter"

class TestHoeGemcutter < Minitest::Test
  include Hoe::Gemcutter

  def test_gemcutter_tasks_defined
    define_gemcutter_tasks
    assert Rake::Task[:release_to_gemcutter]
    assert Rake::Task[:release_to].prerequisites.include?("release_to_gemcutter")
  end

  def sh *cmd_args
    @cmd_args = cmd_args
  end

  def with_config
    yield({ "otp_command" => "echo my_otp_code"}, "~/.hoerc")
  end

  def save_env
    orig_env = ENV.to_h
    yield
  ensure
    ENV.replace orig_env
  end

  def test_gem_push
    save_env do
      gem_push %w[pkg/blah-123.gem]

      exp = %W[#{Gem.ruby} -S gem push pkg/blah-123.gem]
      assert_equal exp, @cmd_args
      assert_equal "my_otp_code", ENV["GEM_HOST_OTP_CODE"]
    end
  end
end
