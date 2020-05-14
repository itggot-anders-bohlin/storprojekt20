require 'sinatra'
require 'slim'
require 'BCrypt'
require 'SQLite3'
require_relative './model.rb'
enable :sessions
include Model
timearray = []
   
# Display Landing Page
#
get('/') do
    slim(:start)
end

# Display page for creating an account
#
get('/users/index') do
    slim(:"users/index")
end

# Creates a new account and redirects to '/register_confirmation'
#
# @param [String] username, the username of the user
# @param [String] password, the password of the user
# @param [String] confirm_password, a confirmation of the user's password
#
# @see Model#register_user
post('/create') do
    username = params["username"]
    password = params["password"]
    confirm_password = params["confirm_password"]
    info = register_user(username, password, confirm_password)
    if info[0] == '/register_confirmation'
        session[:user_id] = info[1]
        session[:username] = info[2]
    else
        session[:error] = info[1]
    end
    redirect(info[0])
end

# Display page that confirms registration of an account
#
get('/register_confirmation') do
    slim(:register_confirmation)
end

# Display page for logging in to an account
#
get('/users/new') do
    slim(:"users/new")
end

# Logs in to an account and redirects to '/shop/index'
#
# @param [String] username, the username of the user
# @param [String] password, the password of the user
#
# @see Model#login_user
post('/login') do
    username = params["username"]
    password = params["password"]
    info = login_user(username, password, timearray)
    if info[0] == '/shop/index'
        session[:user_id] = info[1]
        session[:username] = info[2]
    else
        session[:error] = info[1]
    end
    redirect(info[0])
end

#Checks to see that a user is logged in before accessing sites that they shouldn't
#
before("/shop/:id") do
    if session[:user_id] == nil
        session[:error] = "Logga in för att se denna sida."
        redirect('/error')
    end
end

# Display page for adding items to your cart
#
# @see Model#vew_shop
get('/shop/index') do
    info = view_shop()
    slim(:"shop/index", locals:{items:info[1], admin:info[0]})
end

# Adds item to cart and redirects to '/shop/index'
#
# @param [Integer] :id, the id of the item
# 
# @see Model#add_to_cart
post('/shop/:id/add') do
    item_id = params[:id].to_i
    add_to_cart(item_id)
    redirect('/shop/index')
end

# Display page with your cart
#
# @see Model#view_cart
get('/shop/show') do
    info = view_cart()
    slim(:"shop/show", locals:{items:info[0], total:info[1]})
end

# Remove item from your cart and redirect to '/shop/show'
#
# @param [Integer] :id, the id of the item
#
# @see Model#remove_from_cart
post('/shop/show/:id') do
    item_id = params[:id].to_i
    remove_from_cart(item_id)
    redirect('/shop/show')
end

# Adds all the items in your cart to your orders and redirects to '/shop/new'
#
# @see Model#add_to_order
post('/shop/order') do
    add_to_order()
    redirect('/shop/new')
end

# Dispaly page for your orders
#
# @see Model#view_orders
get('/shop/new') do
    orders = view_orders()
    slim(:"shop/new", locals:{orders:orders})
end

# Display page for editing the items in the shop
#
get('/shop/edit') do
    slim(:"shop/edit")
end

# Adds a new item to the shop and redirects to '/shop/edit'
#
# @param [String] title, the title of the item
# @param [Integer] price, the price of the item
# @param [Integer] amount, the amount of the item
#
# @see Model#add_to_shop
post('/shop/add') do
    title=params["title"]
    price=params["price"]
    amount=params["amount"]
    if title == ""
        redirect('/shop/edit')
    end
    add_to_shop(title, price, amount)
    redirect('/shop/edit')
end

# Updates an item already in the shop and redirects to '/shop/edit'
#
# @param [String] title, the title of the item
# @param [Integer] price, the price of the item
# @param [Integer] amount, the amount of the item
#
# @see Model#update_shop
post('/shop/update') do
    title=params["title"]
    price=params["price"]
    amount=params["amount"]
    if title == ""
        redirect('/shop/edit')
    end
    update_shop(title, price, amount)
    redirect('/shop/edit')
end

# Removes an item from the shop and redirects to '/shop/edit'
#
# @param [String] title, the title of the item
#
# @see Model#delete_from_shop
post('/shop/delete') do
    title = params["title"]
    if title == ""
        redirect('/shop/new')
    end
    delete_from_shop(title)
    redirect('/shop/edit')
end

# Removes the specified order and redirects to '/shop/edit'
#
# @param [Integer] user, the user wo placed the order
# @param [Integer] order, the order that has been delivered.
#
# @see Model#deliver
post('/shop/deliver') do
    user_id = params["user"]
    order_id = params["order"]
    deliver(user_id, order_id)
    redirect('/shop/edit')
end

# Display page with an error message
#
get('/error') do
    slim(:error)
end
