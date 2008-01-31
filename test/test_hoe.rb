
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
    boring   = %w(clobber_docs clobber_package gem redocs repackage)
    expected = %w(audit
                  announce
                  check_manifest
                  clean
                  config_hoe
                  debug_gem
                  default
                  docs
                  email
                  generate_key
                  install
                  install_gem
                  multi
                  package
                  post_blog
                  post_news
                  publish_docs
                  release
                  ridocs
                  test
                  test_deps
                  uninstall)
    expected += boring

    spec = Hoe.new('blah', '1.0.0') do |h|
      h.developer("name", "email")
    end

    assert_equal ["name"], spec.author
    assert_equal ["email"], spec.email

    tasks = Rake.application.tasks
    public_tasks = tasks.reject { |t| t.comment.nil? }.map { |t| t.name }.sort

    assert_equal expected.sort, public_tasks
  end
end
