require 'minitest/autorun'
require 'hoe'

Hoe.load_plugins # make sure Hoe::Test is loaded

class TestHoePublish < MiniTest::Unit::TestCase
  def setup
    Rake.application.clear

    @hoe = Hoe.spec 'blah' do
      self.version = '1.0'
      developer 'author', ''
    end

    @hoe.extend Hoe::Publish
  end

  def test_make_rdoc_cmd
    expected = []
    expected << Gem.bin_path('rdoc', 'rdoc')
    expected << '--title' << 'blah-1.0 Documentation'
    expected.concat %w[-o doc]
    expected.concat %w[--main README.txt]
    expected << 'lib'
    expected.concat %w[History.txt Manifest.txt README.txt]

    assert_equal expected, @hoe.make_rdoc_cmd
  end

end

