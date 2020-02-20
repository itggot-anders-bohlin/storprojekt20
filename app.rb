require 'sinatra'
require 'slim'
require 'BCrypt'
require 'SQLite3'

enable :sessions

before do
    session[:user_id] = 1
    if (session[:user_id] == nil) && (request.path_info != '/')
        redirect('/error')
    end
end

def connect_to_db(path)
    db = SQLite3::Database.new("db/storprojekt.db")
    db.results_as_hash = true
    return db
end
   

get('/') do
    slim(:start)
end

get('/users/index') do

    slim(:"users/index")
end

post('/create') do
    db = connect_to_db("db/storprojekt.db")
    username = params["username"]
    password = params["password"]
    confirm_password = params["confirm_password"]
    result = db.execute("SELECT * FROM users WHERE username=?", username)

    if result.empty?
        if password == confirm_password
            password_digest = BCrypt::Password.create(password)
            db.execute("INSERT INTO users(username, password) VALUES (?,?)", [username, password_digest])
            result = db.execute("SELECT id FROM users WHERE username=?", [username])
            session[:user_id] = result.first["id"]
            
            p "here is #{session[:user_id]}"
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
    db = connect_to_db("db/storprojekt.db")
    username = params["username"]
    password = params["password"]
    result = db.execute("SELECT id, password FROM users WHERE username=?", [username])
    if result.empty?
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

get('/shop/index') do
    db = connect_to_db("db/storprojekt.db")
    p session[:user_id]
    result = db.execute("SELECT * FROM items")
    slim(:"shop/index", locals:{items:result})
end

post('/shop/add') do
    db = connect_to_db("db/storprojekt.db")
    title=params["title"]
    price=params["price"]
    amount=params["amount"]
    db.execute("INSERT INTO items(title, price, amount) VALUES (?,?,?)", [title, price, amount])
    redirect('/shop/index')
end

post('/shop/:id') do
    db = connect_to_db("db/storprojekt.db")
    item_id = params[:id].to_i
    db.execute("INSERT INTO item_user_rel(item_id, user_id) VALUES (?,?)", [item_id, session[:user_id]])
    redirect('/shop/index')
end

get('/shop/show') do
    db = connect_to_db("db/storprojekt.db")
    item = db.execute("SELECT item_id FROM item_user_rel WHERE user_id = ?", session[:user_id])
    result = []
    totalprice = 0
    item.each do |el|
        info = db.execute("SELECT * FROM items WHERE id = ?", el["item_id"])
        totalprice = totalprice + info.first["price"].to_i
        result << info
    end
    slim(:"shop/show", locals:{items:result, total:totalprice})
end

post('/shop/show/:id') do
    
    db = connect_to_db("db/storprojekt.db")
    item_id = params[:id].to_i
    db.execute("DELETE FROM item_user_rel WHERE item_id = ? AND user_id = ?", [item_id, session[:user_id]])
    redirect('/shop/show')
end







get('/error') do
    slim(:error)
end
