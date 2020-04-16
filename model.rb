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

def view_shop()
    db = connect_to_db("db/storprojekt.db")
    admin = db.execute("SELECT admin FROM users WHERE id = ?", session[:user_id])
    result = db.execute("SELECT * FROM items")
    return admin, result
end

def add_to_cart(item_id)
    db = connect_to_db("db/storprojekt.db")
    amount = db.execute("SELECT amount FROM cart WHERE item_id = ? AND user_id = ?", [item_id, session[:user_id]])
    if amount == []
        db.execute("INSERT INTO cart(item_id, user_id, amount) VALUES (?,?,?)", [item_id, session[:user_id]], 1)
    else
        amount = amount[0]["amount"] + 1
        db.execute("UPDATE cart SET amount = ? WHERE item_id = ? AND user_id = ?", [amount,  item_id, session[:user_id]])
    end
end

def view_cart()
    db = connect_to_db("db/storprojekt.db")
    item = db.execute("SELECT item_id, amount FROM cart WHERE user_id = ?", session[:user_id])
    result = []
    totalprice = 0
    item.each do |el|
        info = db.execute("SELECT * FROM items WHERE id = ?", el["item_id"])
        info[0][:amount] = el["amount"]
        totalprice = totalprice + (info.first["price"].to_i * el["amount"])
        result << info
    end
    return result, totalprice
end

def remove_from_cart(item_id)
    db = connect_to_db("db/storprojekt.db")
    db.execute("UPDATE cart SET amount = amount-1 WHERE item_id = ? AND user_id = ?", [item_id, session[:user_id]])
    amount = db.execute("SELECT amount FROM cart WHERE item_id = ? AND user_id = ?", [item_id, session[:user_id]])
    if amount[0]["amount"] == 0
        db.execute("DELETE FROM cart WHERE item_id = ? AND user_id = ?", [item_id, session[:user_id]])
    end
end

def add_to_order()
    db = connect_to_db("db/storprojekt.db")
    result = db.execute("SELECT * FROM cart WHERE user_id = ?", session[:user_id])
    result.each do |el|
        stock = db.execute("SELECT amount FROM items WHERE id = ?", el["item_id"])
        if stock[0]["amount"].to_i >= el["amount"].to_i
            db.execute("UPDATE items SET amount = amount - ? WHERE id = ?", [el["amount"], el["item_id"]])
        else
            session[:error] = "En av varorna du försöker beställa är tyvärr slut i lagret."
            redirect('/error')
        end
        db.execute("INSERT INTO orders(user_id, item_id, amount) VALUES (?,?,?)", [session[:user_id], el["item_id"], el["amount"]])
    end
    db.execute("DELETE FROM cart WHERE user_id = ?", session[:user_id])
end

def view_orders()
    db = connect_to_db("db/storprojekt.db")
    orders = db.execute("SELECT * FROM orders WHERE user_id = ?", session[:user_id])
    orders.each do |el|
        item = db.execute("SELECT title FROM items WHERE id = ?", el["item_id"])
        el["item_id"] = item[0]["title"]
    end
    return orders
end

def add_to_shop(title, price, amount)
    db = connect_to_db("db/storprojekt.db")
    db.execute("INSERT INTO items(title, price, amount) VALUES (?,?,?)", [title, price, amount])
end

def update_shop(title, price, amount)
    db = connect_to_db("db/storprojekt.db")
    db.execute("UPDATE items SET price = ?, amount = ? WHERE title = ?", [price, amount, title])
end

def delete_from_shop(title)
    db = connect_to_db("db/storprojekt.db")
    db.execute("DELETE FROM items WHERE title = ?", title)
end

def deliver(user_id, order_id)
    db = connect_to_db("db/storprojekt.db")
    db.execute("DELETE FROM orders WHERE user_id = ? AND id = ?", [user_id, order_id])
end