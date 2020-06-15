require "rubygems"
require "minitest/autorun"
require "hoe"

class TestHoePublish < Minitest::Test
  def setup
    @hoe = Hoe.spec "blah" do
      self.version = "1.0"

      developer "author", ""
      license "MIT"
    end
  end

  make_my_diffs_pretty!

  def linux? platform = RUBY_PLATFORM # TODO: push up to minitest?
    /linux/ =~ platform
  end

  def test_make_rdoc_cmd
    expected = %W[
                #{Gem.ruby}
                #{Gem.bin_wrapper "rdoc"}
                --title blah-1.0\ Documentation
                -o doc
                --main README.rdoc
                lib
                History.rdoc Manifest.txt README.rdoc
               ]

    skip if linux?
    assert_equal expected, @hoe.make_rdoc_cmd
  end
end
