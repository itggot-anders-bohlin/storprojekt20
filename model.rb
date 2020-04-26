module Model

    # Connects to the database
    # 
    # @return 
    def connect_to_db(path)
        db = SQLite3::Database.new("db/storprojekt.db")
        db.results_as_hash = true
        return db
    end

    # Registers a user 
    #
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

    # logs a user in
    #
    def login_user(username, password, timearray)
        db = connect_to_db("db/storprojekt.db")
        result = db.execute("SELECT id, password FROM users WHERE username=?", [username])
        if result.empty?
            session[:error] = "Det finns inget konto med detta användarnamn"
            redirect("/users/new")
        end
        user_id = result.first["id"]
        password_digest = result.first["password"]
        if BCrypt::Password.new(password_digest) == password
            session[:username] = username
            session[:user_id] = user_id
            redirect("/shop/index")
        else
            session[:error] = "Fel lösenord"
            timearray << Time.now.to_i
            if timearray.length > 4 
                if Time.now.to_i - timearray[0] < 10
                    time = Time.now.to_i
                    session[:error] = "Du har försökt för många lösenord på för kort tid, vänta 5 sekunder"
                    redirect("/users/new")
                    timearray = []
                end
                
                timearray.shift
            end
            
            redirect("/users/new")
        end
        
    end

    # Finds whether the current user is an admin and what items are currently in the shop
    #
    # @return [Hash] 
    #   * admin [Integer] whether the current user is an admin
    # @return [Hash] 
    #   * id [Integer] the id of the item
    #   * title [String] the title of the item
    #   * amount [Integer] the amount of the item
    #   * price [Integer] the price of the item
    def view_shop()
        db = connect_to_db("db/storprojekt.db")
        admin = db.execute("SELECT admin FROM users WHERE id = ?", session[:user_id])
        result = db.execute("SELECT * FROM items")
        return admin, result
    end

    # Adds items to the cart
    #
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

    # Finds items in your cart and calculates the total prce of them
    #
    # @return [Hash] 
    #   * id [Integer] the id of the item
    #   * title [String] the title of the item
    #   * amount [Integer] the amount of the item
    #   * price [Integer] the price of the item
    #
    # @return [Integer] totalprice, the total price of the items in the cart
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

    # Removes an item from the cart
    #
    def remove_from_cart(item_id)
        db = connect_to_db("db/storprojekt.db")
        db.execute("UPDATE cart SET amount = amount-1 WHERE item_id = ? AND user_id = ?", [item_id, session[:user_id]])
        amount = db.execute("SELECT amount FROM cart WHERE item_id = ? AND user_id = ?", [item_id, session[:user_id]])
        if amount[0]["amount"] == 0
            db.execute("DELETE FROM cart WHERE item_id = ? AND user_id = ?", [item_id, session[:user_id]])
        end
    end

    # Adds the items in the cart to an order and removes the amount of each item from the stock
    #
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

    # Selects the orders of the current user
    #
    # @return [Hash] 
    #   * id [Integer] the id of the item
    #   * title [String] the title of the item
    #   * amount [Integer] the amount of the item
    #   * price [Integer] the price of the item
    def view_orders()
        db = connect_to_db("db/storprojekt.db")
        orders = db.execute("SELECT * FROM orders WHERE user_id = ?", session[:user_id])
        orders.each do |el|
            item = db.execute("SELECT title FROM items WHERE id = ?", el["item_id"])
            el["item_id"] = item[0]["title"]
        end
        return orders
    end

    # Adds a new item to the shop
    #
    def add_to_shop(title, price, amount)
        db = connect_to_db("db/storprojekt.db")
        db.execute("INSERT INTO items(title, price, amount) VALUES (?,?,?)", [title, price, amount])
    end

    # Updates an item in the shop
    #
    def update_shop(title, price, amount)
        db = connect_to_db("db/storprojekt.db")
        db.execute("UPDATE items SET price = ?, amount = ? WHERE title = ?", [price, amount, title])
    end

    # Deletes an item from the shop
    #
    def delete_from_shop(title)
        db = connect_to_db("db/storprojekt.db")
        db.execute("DELETE FROM items WHERE title = ?", title)
    end

    # Deletes an order
    #
    def deliver(user_id, order_id)
        db = connect_to_db("db/storprojekt.db")
        db.execute("DELETE FROM orders WHERE user_id = ? AND id = ?", [user_id, order_id])
    end
end