# -*- ruby -*-

$: << 'lib'

require './lib/hoe.rb'

# TODO:
# Hoe.plugin :perforce
# Hoe.plugin :minitest

Hoe.add_include_dirs("../../minitest/dev/lib")

Hoe.spec "hoe" do
  developer "Ryan Davis", "ryand-ruby@zenspider.com"

  self.rubyforge_name = "seattlerb"
  self.testlib        = :minitest

  blog_categories << "Seattle.rb" << "Ruby"

  pluggable!
end

# vim: syntax=Ruby
