require 'json'
require 'redis'
require 'fileutils'

module CRNotes

	LASTID_SUFFIX = "_lastid"
	NAME_SUFFIX = "_name"
	TEXT_SUFFIX = "_text"
	NOTES_SUFFIX = "_notes"
	USERS_KEY = "users"
	
	def self.next_id(redis, scheme)
		scheme + "_" + redis.incr(scheme + LASTID_SUFFIX).to_s
	end
	
	def self.del_idcounters(redis)
		redis.del "note" + LASTID_SUFFIX
		redis.del "user" + LASTID_SUFFIX
	end
	
	class Note
		attr_reader :id, :name, :text

		def initialize(redis, id, new = false)
			@redis = redis
			@id = id
			if new then create id else load end
		end
		
		def create(name)
			@id = CRToDo::next_id(@redis, "todolist")
			@redis[@id + NAME_SUFFIX] = @name = name
			@redis[@id + TEXT_SUFFIX] = @text = ""
		end
		
		def load
			@name = @redis[@id + NAME_SUFFIX]
			@text = @redis[@id + TEXT_SUFFIX]
		end
		
		def name=(newname)
			@redis[@id + NAME_SUFFIX] = @name = newname
		end
		
		def text=(newtext)
			@redis[@id + TEXT_SUFFIX] = @text = newtext
		end

		def delete
			@redis.del @id + NAME_SUFFIX
			@redis.del @id + TEXT_SUFFIX
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
			@id = id
			@notes = {}
			if new then create id else load end
		end
		
		def create(name)
			@id = CRToDo::next_id(@redis, "user")
			self.name = name
		end
		
		def load
			@name = @redis[@id + NAME_SUFFIX]
			@redis.hvals(@id + NOTES_SUFFIX).each do |note_id|
			  note = Note.new @redis, note_id, false
				@notes[note.name] = note
			end
		end
		
		def name=(newname)
			@redis[@id + NAME_SUFFIX] = @name = newname
		end

		def add_note(name)
			return nil unless Note.safe_name? name
			note = Note.new @redis, name, true
			@notes[note.name] = note
			@redis.hset @id + NOTES_SUFFIX, note.name, note.id
			return name
		end

		def delete_note(name)
			@notes[name].delete
			@notes.delete(name)
			@redis.hdel @id + NOTES_SUFFIX, name
			return name
		end

		def rename_note(oldname, newname)
			return nil unless Note.safe_name? newname
			note = @notes.delete(oldname)
			note.name = newname
			@notes[newname] = list
			@redis.hdel @id + NOTES_SUFFIX, oldname
			@redis.hset @id + NOTES_SUFFIX, newname, note.id
			return newname
		end

		def to_json(*a)
			@notes.keys.sort.to_json(*a)
		end

		def delete
			@notes.values.each {|l| l.delete}
			@redis.del @id + NAME_SUFFIX
			@redis.del @id + NOTES_SUFFIX
		end
	end

	class DB
		attr_reader :users, :redis

		def initialize(host, port, db)
			@redis = Redis.new :host => host, :port => port, :db => db
			@users = {}
			@redis.hvals(USERS_KEY).each do |userid|
				user = User.new(@redis, userid)
				@users[user.name] = user
			end
		end
		
		def get_user(username)
			unless @users.key? username
				add_user username
			end
			return @users[username]
		end

		def add_user(username)
			return nil unless User.safe_name? username
			@users[username] = User.new(@redis, username, true)
			@redis.hset USERS_KEY, username, @users[username].id
			return username
		end

		def delete_user(username)
			@users[username].delete
			@users.delete(username)
			@redis.hdel USERS_KEY, username
			return username
		end
		
		def delete
			@users.values.each {|u| u.delete}
			@redis.del USERS_KEY
		end
	end
end

