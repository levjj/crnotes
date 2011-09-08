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
		@note = CRNotes::Note.new @redis, nil, NOTE1
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

	it "allows changing the name" do
		@note.name = NOTE2
		@note.name.should == NOTE2
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
		note = @user.add_note NOTE1
		note.name.should == NOTE1
		@user.notes.size.should == 1
		note2 = @user.notes[note.id]
		note2.name.should == NOTE1
		note2.text.empty?.should == true
		@redis.dbsize.should == 6
	end

	it "rejects note names with slashes" do
		lambda {@user.add_note('/' + NOTE1)}.should raise_error(RuntimeError)
		@user.notes.empty?.should == true
	end

	it "rejects note names with nullbytes" do
		lambda {@user.add_note('\0' + NOTE1)}.should raise_error(RuntimeError)
		@user.notes.empty?.should == true
	end

	it "rejects empty note names" do
		lambda {@user.add_note('')}.should raise_error(RuntimeError)
		@user.notes.empty?.should == true
	end

	it "rejects too long note names" do
		lambda {@user.add_note('a' * 256)}.should raise_error(RuntimeError)
		@user.notes.empty?.should == true
	end

	it "supports deletion of notes" do
		note = @user.add_note NOTE1
		@user.notes.size.should == 1
		@user.delete_note note.id
		@user.notes.empty?.should == true
		@redis.dbsize.should == 3
	end

	it "serializes to JSON" do
		@user.to_json.should ==  '[]'
		note = @user.add_note NOTE1
		json = JSON.parse(@user.to_json)
		(json.is_a? Array).should == true
		json.size.should == 1
		json[0]["id"].should == note.id
		json[0]["name"].should == NOTE1
	end
end

describe CRNotes::DB do
	before(:each) do
		@redis = Redis.new :host => '127.0.0.1', :port => '6379', :db => 3
		@db = CRNotes::DB.new @redis
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
		user.notes.empty?.should == true
		@redis.dbsize.should == 3
	end

	it "rejects usernames with slashes" do
		lambda {@db.add_user('/' + TESTUSER)}.should raise_error(RuntimeError)
		@db.users.empty?.should == true
	end

	it "rejects usernames with nullbytes" do
		lambda {@db.add_user('\0' + TESTUSER)}.should raise_error(RuntimeError)
		@db.users.empty?.should == true
	end

	it "rejects empty usernames" do
		lambda {@db.add_user('')}.should raise_error(RuntimeError)
		@db.users.empty?.should == true
	end

	it "rejects too long usernames" do
		lambda {@db.add_user('a' * 256)}.should raise_error(RuntimeError)
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

