require 'rubygems'
require 'json'
require 'crnotes'

TESTUSER = "user@example.com"

NOTE1 = "Test Note"
NOTE2 = "Second Note"

NOTETEXT = "This is just an example"

describe CRNotes::Note do
	before(:each) do
		@redis = Redis.new :host => '127.0.0.1', :port => '6379', :db => 3
		@redis.flushdb
		@note = CRNotes::Note.new @redis, NOTE1, true
	end

	after(:each) do
		@note.delete
		CRNotes::del_idcounters(@redis)
		@redis.dbsize.should == 0
	end

	it "stores the name" do
		@note.name.should == NOTE1
		@redis.dbsize.should == 3
	end

	it "has no text after creation" do
		@note.text.empty?.should == true
	end

	it "allows changing the text" do
		@note.text = NOTETEXT
		@note.text.should == NOTETEXT
	end
end

describe CRNotes::User do
	before(:each) do
		@redis = Redis.new :host => '127.0.0.1', :port => '6379', :db => 3
		@redis.flushdb
		@user = CRNotes::User.new @redis, TESTUSER, true
	end

	after(:each) do
		@user.delete
		CRNotes::del_idcounters(@redis)
		@redis.dbsize.should == 0
	end

	it "has no notes after creation" do
		@user.notes.empty?.should == true
		@redis.dbsize.should == 2
	end

	it "stores newly created empty notes" do
		name = @user.add_note NOTE1
		name.should == NOTE1
		@user.notes.size.should == 1
		note = @user.notes[NOTE1]
		note.name.should == NOTE1
		note.text.empty?.should == true
		@redis.dbsize.should == 6
	end

	it "rejects note names with slashes" do
		name = @user.add_note('/' + NOTE1)
		name.nil?.should == true
		@user.notes.empty?.should == true
	end

	it "rejects note names with nullbytes" do
		name = @user.add_note('\0' + NOTE1)
		name.nil?.should == true
		@user.notes.empty?.should == true
	end

	it "rejects empty note names" do
		name = @user.add_note('')
		name.nil?.should == true
		@user.notes.empty?.should == true
	end

	it "rejects too long note names" do
		name = @user.add_note('a' * 256)
		name.nil?.should == true
		@user.notes.empty?.should == true
	end

	it "stores newly created todolists with one entry" do
		@todouser.add_list LIST1
		@todouser.lists.size.should == 1
		list = @todouser.lists[LIST1]
		list.add_todo TODO2
		list.name.should == LIST1
		list.entries.size.should == 1
	end

	it "supports renaming of notes" do
		@user.add_note LIST1
		@user.notes.size.should == 1
		@user.notes.values[0].name.should == LIST1
		@user.rename_note(NOTE1, NOTE1 + "2")
		@user.notes.size.should == 1
		@user.notes.values[0].name.should == LIST1 + "2"
		@redis.dbsize.should == 6
	end

	it "supports deletion of notes" do
		@user.add_note NOTE1
		@user.notes.size.should == 1
		@user.delete_note NOTE1
		@user.notes.empty?.should == true
		@redis.dbsize.should == 3
	end

	it "serializes to JSON" do
		@user.to_json.should ==  '[]'
		@user.add_note NOTE1
		@user.to_json.should ==  '["%s"]' % NOTE1
	end

	it "serializes multiple lists in alphabetic order to JSON" do
		@user.add_note NOTE1
		@user.add_note NOTE2
		json = JSON.parse @user.to_json
		json.size.should == 2
		json[0].should == NOTE2
		json[1].should == NOTE1
		@redis.dbsize.should == 8
	end
end

describe CRNotes::DB do
	before(:each) do
		@db = CRNotes::DB.new '127.0.0.1', '6379', 3
		@redis = @db.redis
		@redis.flushdb
	end

	after(:each) do
		@db.delete
		CRNotes::del_idcounters(@redis)
		@redis.dbsize.should == 0
	end

	it "has no users after creation" do
		@db.users.empty?.should == true
		@redis.dbsize.should == 0
	end

	it "stores newly added users" do
		user = @db.add_user TESTUSER
		user.should == TESTUSER
		@db.users.size.should == 1
		user = @db.users[TESTUSER]
		user.name.should == TESTUSER
		user.lists.empty?.should == true
		@redis.dbsize.should == 3
	end

	it "rejects usernames with slashes" do
		user = @db.add_user('/' + TESTUSER)
		user.nil?.should == true
		@db.users.empty?.should == true
	end

	it "rejects usernames with nullbytes" do
		user = @db.add_user('\0' + TESTUSER)
		user.nil?.should == true
		@db.users.empty?.should == true
	end

	it "rejects empty usernames" do
		user = @db.add_user ''
		user.nil?.should == true
		@db.users.empty?.should == true
	end

	it "rejects too long usernames" do
		user = @db.add_user('.' * 256)
		user.nil?.should == true
		@db.users.empty?.should == true
	end

	it "creates users automatically when not present" do
		user = @db.get_user TESTUSER
		user.name.should == TESTUSER
		@db.users.size.should == 1
		@redis.dbsize.should == 3
		user2 = @db.get_user TESTUSER
		user2.name.should == TESTUSER
		@db.users.size.should == 1
		user.should == user2
	end

	it "supports deletion of users" do
		@db.add_user TESTUSER
		@db.users.size.should == 1
		@db.delete_user TESTUSER
		@db.users.empty?.should == true
		@redis.dbsize.should == 1
	end
end

