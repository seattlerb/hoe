# -*- ruby -*-

$:.unshift "lib"
require "./lib/hoe.rb"

Hoe.plugin :seattlerb
Hoe.plugin :isolate
Hoe.plugin :rdoc
Hoe.plugin :cov

Hoe.spec "hoe" do
  developer "Ryan Davis", "ryand-ruby@zenspider.com"

  self.group_name = "seattlerb"

  blog_categories << "Seattle.rb" << "Ruby"

  license "MIT"

  pluggable!
  require_rubygems_version ">= 3.0"
  require_ruby_version [">= 2.7"]

  dependency "rake", [">= 0.8", "< 15.0"] # FIX: to force it to exist pre-isolate
end

task :plugins do
  puts `find lib/hoe -name \*.rb | xargs grep -h module.Hoe::`.
    gsub(/module/, "*")
end

task :known_plugins do
  dep         = Gem::Dependency.new(/^hoe-/, Gem::Requirement.default)
  fetcher     = Gem::SpecFetcher.fetcher
  spec_tuples = fetcher.search_for_dependency(dep).flatten(1)

  max = spec_tuples.map { |(tuple, _source)| tuple.name.size }.max

  spec_tuples.sort_by { |(tuple, _source)| tuple.name }.each do |(tuple, source)|
    spec = source.fetch_spec(tuple)
    summary = spec
                .summary
                .gsub(/\[([^\]]+)\](?:[\[\(].*?[\]\)])?/, '\1')

    puts "* %-#{max}s - %s (%s)" % [spec.name, summary, spec.authors.first]
  end
end

task :docs do
  cp "Hoe.pdf", "doc"
  sh "chmod ug+w doc/Hoe.pdf"
end

# vim: syntax=ruby
