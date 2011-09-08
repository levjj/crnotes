require 'rubygems'
require 'sinatra'
require 'erb'
require 'yaml'
require 'openid'
require 'openid/store/filesystem'
require 'openid/extensions/ax'
require 'crnotes'

PROVIDERS = {"google" => "https://www.google.com/accounts/o8/id",
            "yahoo" => "http://www.yahoo.com/"}

EMAIL_URI = "http://axschema.org/contact/email"
CONFIGFILENAME = "config.yml"
LIBDIR = File.dirname(File.expand_path(__FILE__))
CONFIGFILE = File.join(LIBDIR, "..", CONFIGFILENAME)
OPENIDDIR =  File.join(LIBDIR, "..", "openid")

module CRNotes
	class Application < Sinatra::Application
		def initialize
			super
			if !File.exists?(CONFIGFILE) then
				@configerror = "Required #{CONFIGFILENAME} does not exists"
			else
				cnf = YAML.load_file CONFIGFILE
				if !cnf["redis"] || !cnf["redis"]["host"] || !cnf["redis"]["port"] ||
					!cnf["redis"]["db"] then
					@configerror = '<pre>#{CONFIGFILENAME}</pre> malformed.'
				else
					rcnf = cnf["redis"]
					begin
						@redis = Redis.new :host => rcnf["host"],
						                   :port => rcnf["port"],
						                   :db => rcnf["db"]
						@store = OpenID::Store::Filesystem.new(OPENIDDIR)
					rescue Exception => e
						@configerror = e.to_s
					end
				end
			end
		end

		def openid_consumer
			@openid_consumer ||= OpenID::Consumer.new(session, @store)
		end

		def root_url
			request.url.match(/(^.*\/{2}[^\/]*)/)[1]
		end
		
		def userblock
			if @error then
				''
			elsif session[:user] then
				ERB::Util.h(session[:user]) + ', <a href="/logout">Sign out</a>'
			else
				'Not logged in'
			end
		end

		error do
			@error = env['sinatra.error'].message
			erb :error
		end

		enable :sessions

		get '/login' do
			erb :login
		end

		post '/login' do
			provider = PROVIDERS[params[:provider]]
			raise "Invalid Service" if provider.nil?
			begin
				req = openid_consumer.begin provider
				ax = OpenID::AX::FetchRequest.new
				ax.add OpenID::AX::AttrInfo.new(
					"http://axschema.org/contact/email", nil, true)
				req.add_extension(ax)
			rescue OpenID::DiscoveryFailure => why
				raise "Sorry, we couldn't find your identifier '#{provider}'"
			else
				redirect req.redirect_url(root_url,
				                          root_url + "/logincomplete")
			end
		end

		get '/logincomplete' do
			res = openid_consumer.complete(params, request.url)
			case res.status
				when OpenID::Consumer::FAILURE
					raise "Sorry, we could not authenticate you.\n" + res.message
				when OpenID::Consumer::SETUP_NEEDED
					raise "Immediate request failed - Setup Needed"
				when OpenID::Consumer::CANCEL
					raise "Login cancelled."
				when OpenID::Consumer::SUCCESS
					ax = OpenID::AX::FetchResponse.from_success_response res
					if ax.data[EMAIL_URI].nil? || ax.data[EMAIL_URI].empty?
						raise "Email address couldn't be obtained"
					end
					session[:user] = ax.data[EMAIL_URI][0]
					redirect '/'
			end
		end

		def logged_in?
			!session[:user].nil?
		end

		get '/logout' do
			session[:user] = nil
			redirect '/login'
		end

		before do
		  if @configerror then
				raise @configerror
		  elsif request.path_info =~ /^(\/)?log/ then
			elsif not logged_in? then
				redirect '/login'
			else
				@db = CRNotes::DB.new @redis
				@model = @db.get_user session[:user]
			end
		end
		
		get '/' do
			erb :index
		end

		get '/api/' do
			@model.to_json
		end

		post '/api/' do
			request.body.rewind
			data = JSON.parse request.body.read
			@model.add_note(data["name"]).to_json
		end

		get '/api/:id' do |id|
			@model.notes[id].to_json
		end

		put '/api/:id' do |id|
			request.body.rewind
			data = JSON.parse request.body.read
			note = @model.notes[id]
			note.name = data["name"] unless data["name"].nil?
			note.text = data["text"] unless data["text"].nil?
			note.to_json
		end
		
		delete '/api/:id' do |id|
			@model.delete_note id
		end
	end
end

