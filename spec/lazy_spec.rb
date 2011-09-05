require 'rubygems'
require 'crnotes'

USER = "user@example.com"
LIST = "Test List"
NOTE = "Building a hours"
TEXT = "This is really easy."

describe CRNotes, "lazy loading" do
	before(:all) do
		@redis = Redis.new :host => '127.0.0.1', :port => '6379', :db => 3
		db = CRNotes::DB.new @redis
		@redis.flushdb
		user = db.get_user USER
		user.add_note NOTE
		user.notes[NOTE].text = TEXT
	end
	
	before(:each) do
		@redis.client.disconnect
		@db = CRNotes::DB.new @redis
	end
	
	it "loads the user list" do
		@db.users.empty?.should == false
		@db.users.size.should == 1
	end

	it "does not load individual users" do
		@db.users[USER].loaded?.should == false
	end

	it "loads the user upon accessing the notes" do
		user = @db.users[USER]
		user.notes.empty?.should == false
		user.loaded?.should == true
	end

	it "does not load individual notes" do
		@db.users[USER].notes[NOTE].loaded?.should == false
	end

	it "loads the todo list upon accessing the text" do
		note = @db.users[USER].notes[NOTE]
		note.text.empty?.should == false
		note.loaded?.should == true
	end
end

