require "hoe"
require "minitest/autorun"

Hoe.load_plugins

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
    end
  end

  def teardown
    ENV["PRE"]        = @orig_PRE
    ENV["PRERELEASE"] = @orig_PRERELEASE
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
