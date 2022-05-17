require "minitest/autorun"
require "hoe"

Hoe.load_plugins # make sure Hoe::Test is loaded

class TestHoeTest < Minitest::Test
  def setup
    @tester = Module.new do
      include Hoe::Test

      extend self

      initialize_test

      def test_globs
        ["test/test_hoe_test.rb"]
      end
    end
  end

  def assert_deprecated
    err_re = /DEPRECATED:/

    assert_output "", err_re do
      yield
    end
  end

  path    = %w[lib bin test .].join File::PATH_SEPARATOR
  mt_path = %w[lib test .].join File::PATH_SEPARATOR

  EXPECTED = %W[-w -I#{path}
                -e 'require "rubygems"; %srequire "test/test_hoe_test.rb"'
                --].join(" ") + " "

  MT_EXPECTED = %W[-I#{mt_path} -w
                   -e '%srequire "test/test_hoe_test.rb"'
                   --].join(" ") + " "

  def test_make_test_cmd_defaults_to_minitest
    skip "Using TESTOPTS... skipping" if ENV["TESTOPTS"]

    # default
    assert_deprecated do
      autorun = %(require "minitest/autorun"; )
      assert_equal EXPECTED % autorun, @tester.make_test_cmd
    end
  end

  def test_make_test_cmd_for_testunit
    skip "Using TESTOPTS... skipping" if ENV["TESTOPTS"]

    assert_deprecated do
      @tester.testlib = :testunit
      testunit = %(require "test/unit"; )
      assert_equal EXPECTED % testunit, @tester.make_test_cmd
    end
  end

  def test_make_test_cmd_for_minitest
    skip "Using TESTOPTS... skipping" if ENV["TESTOPTS"]

    require "minitest/test_task" # currently in hoe, but will move

    framework = %(require "minitest/autorun"; )

    @tester = Minitest::TestTask.create :test do |t|
      t.libs += Hoe.include_dirs.uniq
      t.test_globs = ["test/test_hoe_test.rb"]
    end

    assert_equal MT_EXPECTED % [framework].join("; "), @tester.make_test_cmd
  end

  def test_make_test_cmd_for_minitest_prelude
    skip "Using TESTOPTS... skipping" if ENV["TESTOPTS"]

    require "minitest/test_task" # currently in hoe, but will move

    prelude = %(require "other/file")
    framework = %(require "minitest/autorun"; )

    @tester = Minitest::TestTask.create :test do |t|
      t.test_prelude = prelude
      t.libs += Hoe.include_dirs.uniq
      t.test_globs = ["test/test_hoe_test.rb"]
    end

    assert_equal MT_EXPECTED % [prelude, framework].join("; "), @tester.make_test_cmd
  end

  def test_make_test_cmd_for_no_framework
    skip "Using TESTOPTS... skipping" if ENV["TESTOPTS"]

    assert_deprecated do
      @tester.testlib = :none
      assert_equal EXPECTED % "", @tester.make_test_cmd
    end
  end

  def test_make_test_cmd_for_faketestlib
    skip "Using TESTOPTS... skipping" if ENV["TESTOPTS"]

    @tester.testlib = :faketestlib
    e = assert_raises(RuntimeError) do
      @tester.make_test_cmd
    end

    assert_equal "unsupported test framework faketestlib", e.to_s
  end
end
