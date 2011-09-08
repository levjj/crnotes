require 'json'
require 'redis'
require 'fileutils'

module CRNotes

	LASTID_SUFFIX = "lastid"
	NAME_SUFFIX = "_name"
	TEXT_SUFFIX = "_text"
	NOTES_SUFFIX = "_notes"
	USERS_KEY = "users"
	
	USER_KEY = "user_"
	NOTE_KEY = "note_"
	
	def self.next_id(redis, scheme)
		redis.incr(scheme + LASTID_SUFFIX).to_s
	end
	
	def self.del_idcounters(redis)
		redis.del USER_KEY + LASTID_SUFFIX
		redis.del NOTE_KEY + LASTID_SUFFIX
	end
	
	class Note
		attr_reader :id, :name, :text

		def initialize(redis, id, name = nil)
			@redis = redis
			@loaded = false
			@id = id.nil? ? create(name) : id
		end
		
		def create(name)
			raise "Unsafe name" unless Note.safe_name?(name)
			@id = CRNotes::next_id(@redis, NOTE_KEY)
			@redis[NOTE_KEY + @id + NAME_SUFFIX] = @name = name
			@redis[NOTE_KEY + @id + TEXT_SUFFIX] = @text = ""
			@loaded = true
			@id
		end
		
		def load
			@name = @redis[NOTE_KEY + @id + NAME_SUFFIX]
			@text = @redis[NOTE_KEY + @id + TEXT_SUFFIX]
			@loaded = true
		end
		
		def loaded?
			@loaded
		end
		
		def name
			load unless loaded?
			@name
		end

		def text
			load unless loaded?
			@text
		end

		def name=(newname)
			@redis[NOTE_KEY + @id + NAME_SUFFIX] = @name = newname
		end
		
		def text=(newtext)
			@redis[NOTE_KEY + @id + TEXT_SUFFIX] = @text = newtext
		end

		def delete
			@redis.del NOTE_KEY + @id + NAME_SUFFIX
			@redis.del NOTE_KEY + @id + TEXT_SUFFIX
		end
		
		def to_json(*a)
			{:id => id, :name => name, :text => text}.to_json(*a)
		end
		
		def self.safe_name?(name)
			return name.length > 0 &&
			       name.length < 255 &&
			       !name.include?('/') &&
			       !name.include?('\0')
		end
	end

	class User
		attr_reader :id, :notes, :name

		def initialize(redis, id, new = false)
			@redis = redis
			@loaded = false
			@id = id
			@notes = {}
			create id if new
		end
		
		def create(name)
			@id = CRNotes::next_id(@redis, USER_KEY)
			self.name = name
			@loaded = true
		end
		
		def loaded?
			@loaded
		end
		
		def load
			@name = @redis[USER_KEY + @id + NAME_SUFFIX]
			@redis.smembers(USER_KEY + @id + NOTES_SUFFIX).each do |noteid|
				@notes[noteid] = Note.new @redis, noteid
			end
			@loaded = true
		end
		
		def name
			load unless loaded?
			@name
		end

		def notes
			load unless loaded?
			@notes
		end
		
		def name=(newname)
			@redis[USER_KEY + @id + NAME_SUFFIX] = @name = newname
		end

		def add_note(name)
			note = Note.new @redis, nil, name
			notes[note.id] = note
			@redis.sadd USER_KEY + @id + NOTES_SUFFIX, note.id
			return note
		end

		def delete_note(id)
			notes[id].delete
			notes.delete(id)
			@redis.srem USER_KEY + @id + NOTES_SUFFIX, id
			return name
		end

		def to_json(*a)
			notes.values.to_json(*a)
		end

		def delete
			notes.values.each {|n| n.delete}
			@redis.del USER_KEY + @id + NAME_SUFFIX
			@redis.del USER_KEY + @id + NOTES_SUFFIX
		end
	end

	class DB
		attr_reader :users, :redis

		def initialize(redis)
			@redis = redis
			@users = {}
			@redis.hgetall(USERS_KEY).each do |username, userid|
				user = User.new(@redis, userid)
				@users[username] = user
			end
		end
		
		def get_user(username)
			unless users.key? username
				add_user username
			end
			return users[username]
		end

		def add_user(username)
			raise "UnsafeName" unless Note.safe_name? username
			users[username] = User.new(@redis, username, true)
			@redis.hset USERS_KEY, username, users[username].id
			return username
		end

		def delete_user(username)
			users[username].delete
			users.delete(username)
			@redis.hdel USERS_KEY, username
			return username
		end
		
		def delete
			users.values.each {|u| u.delete}
			@redis.del USERS_KEY
		end
	end
end

