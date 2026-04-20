require "minitest/autorun"
require "hoe"
require_relative "../lib/hoe/package.rb"

class TestHoePackage < Minitest::Test
  def setup
    @orig_PRE        = ENV["PRE"]
    @orig_PRERELEASE = ENV["PRERELEASE"]

    ENV.delete "PRE"
    ENV.delete "PRERELEASE"

    @tester = Module.new do
      include Hoe::Package

      extend self

      initialize_package

      @spec = Gem::Specification.new do |s|
        s.version = "1.2.3"
      end

      attr_reader :spec

      def with_config
        yield({ "otp_command" => "echo my_otp_code"}, "~/.hoerc")
      end
    end
  end

  def teardown
    ENV["PRE"]        = @orig_PRE
    ENV["PRERELEASE"] = @orig_PRERELEASE
  end

  def assert_task name, *deps
    dep = Rake::Task[name]
    assert dep
    prereqs = dep.prerequisites.map(&:to_sym)
    deps.each do |dep|
      # not asserting existence of tasks because they might be in other plugins
      assert_includes prereqs, dep.to_sym
    end
  end

  def test_package_tasks_defined
    @tester.define_package_tasks

    assert_task :gem, :clean
    assert_task :install_gem, :clean, :package, :check_extra_deps
    assert_task :postrelease
    assert_task :prerelease
    assert_task :release, :prerelease, :release_to, :postrelease
    assert_task :release_sanity
    assert_task :release_to
    assert_task :release_to, :release_to_rubygems
    assert_task :release_to_rubygems, :clean, :package, :release_sanity
  end

  def save_env
    orig_env = ENV.to_h
    yield
  ensure
    ENV.replace orig_env
  end

  def test_gem_push
    def @tester.sh *cmd_args
      @cmd_args = cmd_args
    end

    def @tester.cmd_args
      @cmd_args
    end

    save_env do
      @tester.gem_push %w[pkg/blah-123.gem]

      exp = %W[#{Gem.ruby} -S gem push pkg/blah-123.gem]
      assert_equal exp, @tester.cmd_args
      assert_equal "my_otp_code", ENV["GEM_HOST_OTP_CODE"]
    end
  end

  def test_prerelease_version_pre
    ENV["PRE"] = "pre.0"

    @tester.prerelease_version

    expected = Gem::Version.new "1.2.3.pre.0"

    assert_equal expected, @tester.spec.version
  end

  def test_prerelease_version_prerelease
    ENV["PRERELEASE"] = "prerelease.0"

    @tester.prerelease_version

    expected = Gem::Version.new "1.2.3.prerelease.0"

    assert_equal expected, @tester.spec.version
  end

  def test_prerelease_version_regular
    @tester.prerelease_version

    expected = Gem::Version.new "1.2.3"

    assert_equal expected, @tester.spec.version
  end
end
