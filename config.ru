require 'rubygems'

ENV['RACK_ENV'] = "production"

$: << File.join(File.expand_path(File.dirname(__FILE__)), 'lib')
load 'crnotes_app.rb'
 
run CRNotes::Application.new
