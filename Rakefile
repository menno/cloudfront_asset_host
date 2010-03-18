require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

desc 'Default: run unit tests.'
task :default => :test

desc 'Test the cloudfront_asset_host plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

desc 'Generate documentation for the cloudfront_asset_host plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'CloudfrontAssetHost'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "cloudfront_asset_host"
    gemspec.summary = "Rails plugin to easily and efficiently deploy your assets on Amazon's S3 or CloudFront"
    gemspec.description = "Easy deployment of your assets on CloudFront or S3 using a simple rake-task. When enabled in production, the application's asset_host and public_paths will point to the correct location."
    gemspec.email = "menno@wakoopa.com"
    gemspec.homepage = "http://github.com/menno/cloudfront_asset_host"
    gemspec.authors = ["Menno van der Sman"]
    gemspec.add_dependency 'right_aws'
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install jeweler"
end
