
require 'test/unit/testcase'
require 'hoe'

$rakefile = nil # shuts up a warning in rdoctask.rb

class TestHoe < Test::Unit::TestCase
  def setup
    Rake.application.clear
  end

  ##
  # Yes, these tests suck, but it is damn hard to test this since
  # everything is forked out.

  def test_basics
    boring   = %w(clobber clobber_docs clobber_package doc doc/index.html pkg pkg/blah-1.0.0 pkg/blah-1.0.0.gem pkg/blah-1.0.0.tgz redocs repackage)
    expected = %w(audit announce check_manifest clean debug_gem default docs email gem install install_gem multi package post_news publish_docs release ridocs test test_deps uninstall)
    expected += boring

    Hoe.new('blah', '1.0.0')
    tasks = Rake.application.tasks.map { |t| t.name }.sort

    assert_equal expected.sort, tasks
  end
end
