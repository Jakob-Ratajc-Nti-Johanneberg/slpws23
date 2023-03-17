require 'sinatra'
require 'slim'
require 'sqlite3'
require "sinatra/reloader"
require 'bcrypt'

enable :sessions

# Databaskoppling
db = SQLite3::Database.new("database.db")
db.results_as_hash = true

# Skapa användartabell om den inte redan finns
db.execute("CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY AUTOINCREMENT, username TEXT, password_digest TEXT) STRICT, WITHOUT ROWID")

# Skapa annons-tabell om den inte redan finns
db.execute("CREATE TABLE IF NOT EXISTS ads (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, description TEXT, price INTEGER, user_id INTEGER, FOREIGN KEY(user_id) REFERENCES users(id)) STRICT, WITHOUT ROWID")

# Användarhantering
get '/' do
  slim :index
end

get '/signup' do
slim :signup
end

post '/signup' do
username = params[:username]
password = params[:password]
password_confirmation = params[:password_confirmation]

# Kolla om lösenorden matchar
if password == password_confirmation
  # Kryptera lösenordet
  password_digest = BCrypt::Password.create(password)

  # Lägg till användaren i databasen
  db.execute("INSERT INTO users (username, password_digest) VALUES (?, ?)", [username, password_digest])

  # Redirect to login page after successful signup
  redirect '/login'
else
  slim :signup
end
end

get '/login' do
slim :login
end

post '/login' do
  username = params[:username]
  password = params[:password]

  # Hämta användaren från databasen
  user = db.execute("SELECT * FROM users WHERE username = ?", [username]).first

  # Kolla om lösenordet stämmer
  if user && BCrypt::Password.new(user["password_digest"]) == password
    # Spara användar-ID i sessionen
    session[:user_id] = user["id"]

    redirect '/ads'
  else
    redirect '/ads'
  end
end

get '/logout' do
# Ta bort användar-ID från sessionen
session[:user_id] = nil

redirect '/'
end

# Annons-hantering

get '/ads' do
  # Hämta alla annonser från databasen
  @ads = db.execute("SELECT * FROM ads")

  slim :ads
end

get '/ads/new' do
  # Kolla om användaren är inloggad
  if session[:user_id]
    slim :new_ad
  else
    redirect '/'
  end
end
