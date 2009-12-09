# -*- ruby -*-

$: << 'lib'

require './lib/hoe.rb'

Hoe.plugin :seattlerb

Hoe.spec "hoe" do
  developer "Ryan Davis", "ryand-ruby@zenspider.com"

  self.rubyforge_name = "seattlerb"

  blog_categories << "Seattle.rb" << "Ruby"

  pluggable!
end

[:redocs, :docs].each do |t|
  task t do
    cp "Hoe.pdf", "doc"
  end
end

# vim: syntax=ruby
