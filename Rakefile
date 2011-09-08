#!/usr/bin/env rake

require 'rubygems'
require 'rake'
require 'rake/clean'
require 'rspec'
require 'rspec/core/rake_task'
require 'rdoc/task'

PROJECT_NAME = 'CRNotes'

SRC_FILES = FileList.new('lib/*.rb')
TEST_FILES = FileList.new('spec/*_spec.rb')

desc "Starts CRNotes server with thin"
task :start do |t|
	system "thin -C thin.yml start"
end

desc "Stops CRNotes server with thin"
task :stop do |t|
	system "thin -C thin.yml stop" rescue nil
end

desc "Restarts CRNotes server with thin"
task :restart  => [:stop, :start] do |t|
end

desc "Test the application"
RSpec::Core::RakeTask.new(:rspec) do |rspec|
	rspec.pattern = TEST_FILES
	rspec.rcov = false
	rspec.ruby_opts = ["-Ilib"]
	rspec.rspec_opts = ["--format", "documentation", "--color", "--backtrace"]
end

desc "Test the application with RCov"
RSpec::Core::RakeTask.new(:rcov) do |rspec|
	rspec.pattern = TEST_FILES
	rspec.rcov = true
	rspec.ruby_opts = ["-Ilib"]
	rspec.rcov_opts = ["--no-html", "--no-rcovrt", "--gcc", "--exclude", TEST_FILES]
	rspec.rspec_opts = ["--format", "documentation", "--color", "--backtrace"]
end

desc "Performs a static check of the CRNotes code"
task :check do |check|
	exec "reek -q #{TEST_FILES} #{SRC_FILES}"
	exec "ruby -c -w #{SRC_FILES}}"
end

RDoc::Task.new('doc') do |rdoc|
	rdoc.name = :doc
	rdoc.title = "CRNotes"
	rdoc.main = 'README.markdown'
	rdoc.rdoc_dir = 'doc'
	rdoc.rdoc_files.include #{lib/*.rb README.markdown}
	rdoc.options += [
		'-A',
		"--line-numbers",
	]
end

task :default => :restart
