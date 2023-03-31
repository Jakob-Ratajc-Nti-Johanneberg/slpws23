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

get '/login' do
  slim :login
end

post '/login' do
  username = params[:username]
  password = params[:password]

  # Hämta användaren från databasen
  user = db.execute("SELECT * FROM users WHERE username = ?", [username]).first

  # Kolla om användaren finns och om lösenordet stämmer
  if user && BCrypt::Password.new(user["password_digest"]) == password
    # Spara användar-ID i sessionen
    session[:user_id] = user["id"]

    redirect '/ads'
  else
    # Felaktigt användarnamn eller lösenord
    slim :login, locals: { error: "Felaktigt användarnamn eller lösenord." }
  end
end

# Signup

post '/signup' do
  username = params[:username]
  password = params[:password]
  password_confirmation = params[:password_confirmation]

  # Kolla om användarnamnet redan finns i databasen
  if db.execute("SELECT * FROM users WHERE username = ?", [username]).any?
    # Visar en popup och skickar tillbaka användaren till signup-sidan
    erb :signup, locals: { error: "Användarnamnet är upptaget. Välj ett annat användarnamn." }
  # Kolla om lösenorden matchar
  elsif password == password_confirmation
    # Kryptera lösenordet
    password_digest = BCrypt::Password.create(password)

    # Lägg till användaren i databasen
    db.execute("INSERT INTO users (username, password_digest) VALUES (?, ?)", [username, password_digest])

    redirect '/login'
  else
    slim :signup, locals: { error: "Lösenorden matchar inte." }
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

post '/ads' do
  # Kolla om användaren är inloggad
  if session[:user_id]
    # Hämta data från formuläret
    title = params[:title]
    description = params[:description]
    price = params[:price]

    # Lägg till annonsen i databasen
    user_id = session[:user_id]
    db.execute("INSERT INTO ads (title, description, price, user_id) VALUES (?, ?, ?, ?)", [title, description, price, user_id])

    # Redirect till /ads
    redirect '/ads'
  else
    redirect '/login'
  end
end


get '/ads/new' do
  # Kolla om användaren är inloggad
  if session[:user_id]
    slim :new_ad
  else
    redirect '/'
  end
end

post '/ads/new' do
  title = params[:title]
  description = params[:description]
  price = params[:price]

  # Kolla om användaren är inloggad
  if session[:user_id]
    user_id = session[:user_id]
    db.execute("INSERT INTO ads (title, description, price, user_id) VALUES (?, ?, ?, ?)", [title, description, price, user_id])
    redirect '/ads'
  else
    redirect '/'
  end
end
