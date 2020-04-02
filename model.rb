require 'sinatra'
require 'slim'
require 'BCrypt'
require 'SQLite3'

def connect_to_db(path)
    db = SQLite3::Database.new("db/storprojekt.db")
    db.results_as_hash = true
    return db
end

def register_user(username, password, confirm_password)
    db = connect_to_db("db/storprojekt.db")
    result = db.execute("SELECT * FROM users WHERE username=?", username)

    if result.empty?
        if password == confirm_password
            password_digest = BCrypt::Password.create(password)
            db.execute("INSERT INTO users(username, password, admin) VALUES (?,?,?)", [username, password_digest, 0])
            result = db.execute("SELECT id FROM users WHERE username=?", [username])
            session[:user_id] = result.first["id"]
            session[:username] = username
            redirect('/register_confirmation')
        else
            session[:error] = "Dina lösenord matchar inte"
            redirect('/error')
        end
    else
        session[:error]="Det finns redan ett konto med detta användarnamn"
        redirect('/error')
    end
end

def login_user(username, password)
    db = connect_to_db("db/storprojekt.db")
    result = db.execute("SELECT id, password FROM users WHERE username=?", [username])
    if result.empty?
        session[:error] = "Det finns inget konto med detta användarnamn"
        redirect('/error')
    end
    user_id = result.first["id"]
    password_digest = result.first["password"]
    if BCrypt::Password.new(password_digest) == password
        session[:username] = username
        session[:user_id] = user_id
        redirect("/shop/index")
    end
    
end

