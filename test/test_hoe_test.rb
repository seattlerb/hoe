require "minitest/autorun"
require "hoe"
require "minitest/test_task" # currently in hoe, but will move

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

  path    = %w[lib bin test .].join File::PATH_SEPARATOR
  mt_path = %w[lib test .].join File::PATH_SEPARATOR

  EXPECTED = %W[-w -I#{path}
                -e 'require "rubygems"; %srequire "test/test_hoe_test.rb"'
                --].join(" ") + " "

  MT_EXPECTED = %W[-I#{mt_path} -w
                   -e '%srequire "test/test_hoe_test.rb"'
                   --].join(" ") + " "

  def test_make_test_cmd_for_minitest
    skip "Using TESTOPTS... skipping" if ENV["TESTOPTS"]

    framework = %(require "minitest/autorun"; )

    @tester = Minitest::TestTask.create :testtest do |t|
      t.libs += Hoe.include_dirs.uniq
      t.test_globs = ["test/test_hoe_test.rb"]
    end

    assert_equal MT_EXPECTED % [framework].join("; "), @tester.make_test_cmd
  end

  def test_make_test_cmd_for_minitest_prelude
    skip "Using TESTOPTS... skipping" if ENV["TESTOPTS"]

    prelude = %(require "other/file")
    framework = %(require "minitest/autorun"; )

    @tester = Minitest::TestTask.create :test do |t|
      t.test_prelude = prelude
      t.libs += Hoe.include_dirs.uniq
      t.test_globs = ["test/test_hoe_test.rb"]
    end

    assert_equal MT_EXPECTED % [prelude, framework].join("; "), @tester.make_test_cmd
  end
end
