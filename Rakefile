require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "wwdcdownloader"
  gem.homepage = "https://github.com/jfahrenkrug/WWDC-Downloader"
  gem.license = "MIT"
  gem.summary = %Q{A small tool to download all the sample code of Apple's latest WWDC developer conference}
  gem.description = %Q{At each year's WWDC, Apple releases great sample projects. Unfortunately it is very tedious to manually download all these treasures through your browser. WWDC-Downloader solves this problem for you!}
  gem.email = "johannes@springenwerk.com"
  gem.authors = ["Johannes Fahrenkrug"]
  
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new