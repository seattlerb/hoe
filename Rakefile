# -*- ruby -*-

require './lib/hoe.rb'

Hoe.new("hoe", Hoe::VERSION) do |hoe|
  hoe.rubyforge_name = "seattlerb"
  hoe.developer("Ryan Davis", "ryand-ruby@zenspider.com")
end

task :tasks do
  tasks = `rake -T`.scan(/rake (\w+)\s+# (.*)/)
  tasks.reject! { |t,d| t =~ /^(clobber|re(package|docs))/ }
  max   = tasks.map { |x,y| x.size }.max

  tasks.each do |t,d|
    if ENV['RDOC'] then
      puts "# %-#{max+2}s %s" % [t + "::", d]
    else
      puts "* %-#{max}s - %s" % [t, d]
    end
  end
end

# vim: syntax=Ruby
