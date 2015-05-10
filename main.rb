require 'rubygems'
require 'sinatra'
require 'pry'

set :sessions, true

get '/' do
  erb :set_name
end

get '/test' do
  erb :'test/sample'
end

post '/set_name' do
  session[:player_name] = params[:player_name]
  redirect '/game'
end

get '/game' do
  session[:deck] = [['2', 'H'], ['4', 'S']]
  session[:player_cards] = []
  session[:player_cards] << session[:deck].pop
  erb :game
end