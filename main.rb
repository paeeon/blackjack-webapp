require 'rubygems'
require 'sinatra'
require 'pry'

set :sessions, true

BLACKJACK_AMOUNT = 21
DEALER_MIN_HIT = 17

helpers do
  def calculate_value_of_hand(cards)
    arr = cards.map{|element| element[1]}

    value = 0
    number_of_aces = 0
    arr.each do |a|
      if a.is_a? Integer
        value += a
      elsif a == 'A'
        value += 11
        number_of_aces += 1
      else
        value += 10
      end
    end

    #correct for aces
    if number_of_aces != 0
      number_of_aces.times do |ace|
        if value > 21
          value -= 10
        end
      end
    end
    value
  end

  def card_image(card) #['H', 4]
    suit = case card[0]
      when 'H' then 'hearts'
      when 'D' then 'diamonds'
      when 'C' then 'clubs'
      when 'S' then 'spades'
    end

    value = card[1]
    if ['J', 'Q', 'K', 'A'].include?(value)
      value = case card[1]
        when 'J' then 'jack'
        when 'Q' then 'queen'
        when 'K' then 'king'
        when 'A' then 'ace'
      end
    else
      value = value.to_s
    end

    "<img src='/images/cards/#{suit}_#{value}.jpg'>"
  end

  def winner!(msg)
    @show_hit_or_stay_buttons = false
    @winner = "<strong>#{session[:player_name]} wins $#{session[:bet_amount]*2}!</strong> #{msg} <a href='/bet' class='alert-link'>Play again?</a>"
    session[:scoreboard][:player] += 1
    session[:cash_remaining] += session[:bet_amount]
  end

  def loser!(msg)
    @show_hit_or_stay_buttons = false
    @loser = "<strong>#{session[:player_name]} lost $#{session[:bet_amount]}!</strong> #{msg} <a href='/bet' class='alert-link'>Play again?</a>"
    session[:scoreboard][:dealer] += 1
    session[:cash_remaining] -= session[:bet_amount]
  end

  def tie!(msg)
    @show_hit_or_stay_buttons = false
    @winner = "<strong>It's a tie!</strong> #{msg} <a href='/bet' class='alert-link'>Play again?</a>"
  end
end

before do
  @show_hit_or_stay_buttons = true
end

get '/' do
  if session[:player_name]
    redirect '/game'
  else
    redirect '/new_player'
  end
end

get '/new_player' do
  @new_player = true
  erb :new_player
end

post '/new_player' do
  if params[:player_name] =~ /\A\p{Alnum}+\z/
    session[:player_name] = params[:player_name]
    session[:scoreboard] = {player: 0, dealer: 0}
    session[:cash_remaining] = 20
    redirect '/bet'
  else
    @error = "Hey! It looks like you didn't enter anything, or you didn't enter a real name. Try again!"
    halt erb(:new_player)
  end
end

get '/bet' do
  if session[:cash_remaining] == 0
    redirect '/end'
  end
  @new_player = true
  erb :bet
end

post '/bet' do 
  if !/\A\d+\z/.match(params[:bet_amount]) # If the bet amount made is NOT a positive number
    @error = "Hey! You tryin' to cheat? Not on my clock! Enter a positive amount."
    halt erb(:bet)
  elsif params[:bet_amount].to_i > session[:cash_remaining]
    @error = "You don't have that much money! Try again.."
    halt erb(:bet)
  elsif params[:bet_amount].nil? || params[:bet_amount].to_i == 0
    @error = "You have to bet at least $1. Try again."
    halt erb(:bet)
  else
    session[:bet_amount] = params[:bet_amount].to_i
    redirect '/game'
  end
end

get '/game' do
  @new_player = false
  suits = ['H', 'D', 'C', 'S']
  values = [2, 3, 4, 5, 6, 7, 8, 9, 10, 'J', 'Q', 'K', 'A']
  session[:deck] = suits.product(values).shuffle!
  session[:dealer_cards] = []
  session[:player_cards] = []
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  player_total = calculate_value_of_hand(session[:player_cards])
  dealer_total = calculate_value_of_hand(session[:dealer_cards])
  if player_total == BLACKJACK_AMOUNT
    winner!("#{session[:player_name]} hit blackjack!")
  elsif player_total > BLACKJACK_AMOUNT
    loser!("#{session[:player_name]} busted.")
  elsif dealer_total == BLACKJACK_AMOUNT
    loser!("Dealer hit blackjack.")
  elsif dealer_total > BLACKJACK_AMOUNT
    winner!("Dealer busted at #{dealer_total}.")
  end
  erb :game
end

post '/game/player/hit' do
  session[:player_cards] << session[:deck].pop
  
  player_total = calculate_value_of_hand(session[:player_cards])
  if player_total == BLACKJACK_AMOUNT
    winner!("#{session[:player_name]} hit blackjack!")
  elsif player_total > BLACKJACK_AMOUNT
    loser!("#{session[:player_name]} busted.")
  end
  erb :game, layout: false
end

post '/game/player/stay' do
  @show_hit_or_stay_buttons = false
  @success = "#{session[:player_name]} has chosen to stay."
  redirect '/game/dealer'
end

get '/game/dealer' do
  @dealer_turn = true
  @show_hit_or_stay_buttons = false
  dealer_total = calculate_value_of_hand(session[:dealer_cards])
  if dealer_total == BLACKJACK_AMOUNT
    loser!("Dealer hit blackjack.")
  elsif dealer_total > BLACKJACK_AMOUNT
    winner!("Dealer busted at #{dealer_total}.")
  elsif dealer_total >= DEALER_MIN_HIT
    redirect '/game/compare'
  else
    @show_dealer_hit_button = true
  end
  erb :game, layout: false
end

post '/game/dealer/hit' do
  @dealer_turn = true
  session[:dealer_cards] << session[:deck].pop
  redirect '/game/dealer'
end

get '/game/compare' do
  @dealer_turn = true
  player_total = calculate_value_of_hand(session[:player_cards])
  dealer_total = calculate_value_of_hand(session[:dealer_cards])
  if player_total < dealer_total
    loser!("#{session[:player_name]} stayed at #{player_total}, and the dealer stayed at #{dealer_total}.")
  elsif player_total > dealer_total
    winner!("#{session[:player_name]} stayed at #{player_total}, and the dealer stayed at #{dealer_total}.")
  else
    tie!("Both #{session[:player_name]} and the dealer stayed at #{player_total}.")
  end
  erb :game, layout: false
end

get '/end' do
  erb :end
end
