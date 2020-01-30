require 'sinatra'
require 'slim'
require 'BCrypt'
require 'SQLite3'

enable :sessions

get('/') do
    slim(:start)
end

get('/users/index') do

    slim(:"users/index")
end

post('/create') do
    db = SQLite3::Database.new("db/storprojekt.db")
    username = params["username"]
    password = params["password"]
    confirm_password = params["confirm_password"]
    result = db.execute("SELECT * FROM users WHERE username=?", username)

    if result.empty?
        if password == confirm_password
            password_digest = BCrypt::Password.create(password)
            db.execute("INSERT INTO users(username, password) VALUES (?,?)", [username, password_digest])
            session[:user_id] = db.execute("SELECT ID FROM users WHERE username=?", [username])
            session[:username] = username
            redirect('/register_confirmation')
        else
            redirect('/error')
            
        end
    else
        redirect('/error')
    end

    redirect('/users/index')
end

get('/register_confirmation') do
    slim(:register_confirmation)
end

get('/users/new') do
    slim(:"users/new")
end

post('/login') do
    db = SQLite3::Database.new("db/storprojekt.db")
    username = params["username"]
    password = params["password"]
    db.results_as_hash = true
    result = db.execute("SELECT ID, password FROM users WHERE username=?", [username])
    if result.empty?
        redirect('/error')
    end
    user_id = result.first["ID"]
    password_digest = result.first["password"]
    if BCrypt::Password.new(password_digest) == password
        session[:username] = username
        session[:user_id] = user_id
        redirect("/shop/index")
    end
    
end

get('/shop/index') do
    db = SQLite3::Database.new("db/storprojekt.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM items")
    slim(:"shop/index", locals:{items:result})
end

post('/shop/add') do
    db = SQLite3::Database.new("db/storprojekt.db")
    db.results_as_hash = true
    title=params["title"]
    price=params["price"]
    amount=params["amount"]
    db.execute("INSERT INTO items(title, amount, price) VALUES (?,?,?)", [title, price, amount])
    redirect('/shop/index')
end









get('/error') do
    slim(:error)
end