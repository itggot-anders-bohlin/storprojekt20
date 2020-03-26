require 'sinatra'
require 'slim'
require 'BCrypt'
require 'SQLite3'
require_relative './model.rb'
enable :sessions

before do
    session[:user_id] = 1
    if (session[:user_id] == nil) && (request.path_info != '/')
        redirect('/error')
   end
end
   
get('/') do
    slim(:start)
end

get('/users/index') do
    slim(:"users/index")
end

post('/create') do
    
    username = params["username"]
    password = params["password"]
    confirm_password = params["confirm_password"]
    register_user(username, password, confirm_password)

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
    login_user(username, password)
end

before("/shop/:id") do
    if session[:user_id] == nil
        redirect('/error')
    end
end

get('/shop/index') do
    db = connect_to_db("db/storprojekt.db")
    admin =  db.execute("SELECT admin FROM users WHERE id = ?", session[:user_id])
    result = db.execute("SELECT * FROM items")
    slim(:"shop/index", locals:{items:result, admin:admin})
end

post('/shop/:id/add') do
    db = connect_to_db("db/storprojekt.db")
    item_id = params[:id].to_i
    amount = db.execute("SELECT amount FROM cart WHERE item_id = ? AND user_id = ?", [item_id, session[:user_id]])
    if amount == []
        db.execute("INSERT INTO cart(item_id, user_id, amount) VALUES (?,?,?)", [item_id, session[:user_id]], 1)
    else
        amount = amount[0]["amount"] + 1
        db.execute("UPDATE cart SET amount = ? WHERE item_id = ? AND user_id = ?", [amount,  item_id, session[:user_id]])
    end
    redirect('/shop/index')
end

get('/shop/show') do
    db = connect_to_db("db/storprojekt.db")
    item = db.execute("SELECT item_id, amount FROM cart WHERE user_id = ?", session[:user_id])
    result = []
    totalprice = 0
    item.each do |el|
        info = db.execute("SELECT * FROM items WHERE id = ?", el["item_id"])
        p info[0]
        info[0][:amount] = el["amount"]
        totalprice = totalprice + (info.first["price"].to_i * el["amount"])
        result << info
    end

    slim(:"shop/show", locals:{items:result, total:totalprice})
end

post('/shop/show/:id') do
    db = connect_to_db("db/storprojekt.db")
    item_id = params[:id].to_i
    db.execute("UPDATE cart SET amount = amount-1 WHERE item_id = ? AND user_id = ?", [item_id, session[:user_id]])
    amount = db.execute("SELECT amount FROM cart WHERE item_id = ? AND user_id = ?", [item_id, session[:user_id]])
    if amount[0]["amount"] == 0
        db.execute("DELETE FROM cart WHERE item_id = ? AND user_id = ?", [item_id, session[:user_id]])
    end
    redirect('/shop/show')
end

post('/shop/order') do
    db = connect_to_db("db/storprojekt.db")
    result = db.execute("SELECT * FROM cart WHERE user_id = ?", session[:user_id])
    p result
    result.each do |el|
        p el
        p el["item_id"]
        db.execute("INSERT INTO orders(user_id, item_id, amount) VALUES (?,?,?)", [session[:user_id], el["item_id"], el["amount"]])
    end
    db.execute("DELETE FROM cart WHERE user_id = ?", session[:user_id])
    redirect('/shop/new')
end

get('/shop/new') do
    db = connect_to_db("db/storprojekt.db")
    orders = db.execute("SELECT * FROM orders WHERE user_id = ?", session[:user_id])
    p orders
    orders.each do |el|
        item = db.execute("SELECT title FROM items WHERE id = ?", el["item_id"])
        el["item_id"] = item[0]["title"]
    end
    p orders
    
    slim(:"shop/new", locals:{orders:orders})
end

get('/shop/edit') do
    slim(:"shop/edit")
end

post('/shop/add') do
    p "hej"
    db = connect_to_db("db/storprojekt.db")
    title=params["title"]
    price=params["price"]
    amount=params["amount"]
    if title == ""
        redirect('/shop/edit')
    end
    db.execute("INSERT INTO items(title, price, amount) VALUES (?,?,?)", [title, price, amount])
    redirect('/shop/edit')
end

post('/shop/update') do
    db = connect_to_db("db/storprojekt.db")
    title=params["title"]
    price=params["price"]
    amount=params["amount"]
    if title == ""
        redirect('/shop/edit')
    end
    db.execute("UPDATE items SET price = ?, amount = ? WHERE title = ?", [price, amount, title])
    redirect('/shop/edit')
end

post('/shop/delete') do
    db = connect_to_db("db/storprojekt.db")
    title=params["title"]
    if title == ""
        redirect('/shop/new')
    end
    db.execute("DELETE FROM items WHERE title = ?", title)
    redirect('/shop/edit')
end

get('/error') do
    slim(:error)
end
