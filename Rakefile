# -*- ruby -*-

$: << 'lib'

require './lib/hoe.rb'

Hoe.plugin :seattlerb

Hoe.spec "hoe" do
  developer "Ryan Davis", "ryand-ruby@zenspider.com"

  self.rubyforge_name = "seattlerb"

  blog_categories << "Seattle.rb" << "Ruby"

  pluggable!
  require_ruby_version '>= 1.3.6'
end

task :plugins do
  puts `find lib/hoe -name \*.rb | xargs grep -h module.Hoe::`.
    gsub(/module/, '*')
end

[:redocs, :docs].each do |t|
  task t do
    cp "Hoe.pdf", "doc"
    sh "chmod u+w doc/Hoe.pdf"
  end
end

# vim: syntax=ruby
