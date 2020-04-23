require 'sinatra'
require 'slim'
require 'BCrypt'
require 'SQLite3'
require_relative './model.rb'
enable :sessions
timearray = []
before do
   session[:user_id] = 1 #ta bort innan inlämning
end
   
get('/') do
    session[:error] = nil
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
    username = params["username"]
    password = params["password"]
    
    login_user(username, password, timearray)
end



before("/shop/:id") do
    if session[:user_id] == nil
        session[:error] = "Logga in för att se denna sida."
        redirect('/error')
    end
end

get('/shop/index') do
    info = view_shop()
    slim(:"shop/index", locals:{items:info[1], admin:info[0]})
end

post('/shop/:id/add') do
    item_id = params[:id].to_i
    add_to_cart(item_id)
    redirect('/shop/index')
end

get('/shop/show') do
    info = view_cart()
    slim(:"shop/show", locals:{items:info[0], total:info[1]})
end

post('/shop/show/:id') do
    item_id = params[:id].to_i
    remove_from_cart(item_id)
    redirect('/shop/show')
end

post('/shop/order') do
    add_to_order()
    redirect('/shop/new')
end

get('/shop/new') do
    orders = view_orders()
    slim(:"shop/new", locals:{orders:orders})
end

get('/shop/edit') do
    slim(:"shop/edit")
end

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

post('/shop/delete') do
    title = params["title"]
    if title == ""
        redirect('/shop/new')
    end
    delete_from_shop(title)
    redirect('/shop/edit')
end

post('/shop/deliver') do
    user_id = params["user"]
    order_id = params["order"]
    deliver(user_id, order_id)
    redirect('/shop/edit')
end

get('/error') do
    slim(:error)
end
