require 'sinatra'
require 'slim'
require 'BCrypt'
require 'SQLite3'

def connect_to_db(path)
    db = SQLite3::Database.new("db/storprojekt.db")
    db.results_as_hash = true
    return db
end

def register_user()
    
end