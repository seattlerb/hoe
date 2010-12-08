# -*- ruby -*-

$: << 'lib'

require './lib/hoe.rb'

Hoe.add_include_dirs "../../minitest/dev/lib"

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

task :known_plugins do
  dep         = Gem::Dependency.new(/^hoe-/, Gem::Requirement.default)
  fetcher     = Gem::SpecFetcher.fetcher
  spec_tuples = fetcher.find_matching dep

  max = spec_tuples.map { |(tuple, source)| tuple.first.size }.max

  spec_tuples.each do |(tuple, source)|
    spec = Gem::SpecFetcher.fetcher.fetch_spec(tuple, URI.parse(source))
    puts "* %-#{max}s - %s (%s)" % [spec.name, spec.summary, spec.authors.first]
  end
end

[:redocs, :docs].each do |t|
  task t do
    cp "Hoe.pdf", "doc"
    sh "chmod u+w doc/Hoe.pdf"
  end
end

# vim: syntax=ruby
