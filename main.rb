require 'rubygems'
require 'sinatra'
require 'pry'

set :sessions, true

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

  def bust?(cards)
    calculate_value_of_hand(cards) > 21
  end

  def blackjack?(cards)
    calculate_value_of_hand(cards) == 21
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

  def check_player(player_cards)
    if bust?(session[:player_cards])
      @lose = "Uh oh, you busted! Sorry, you lose! <a href='/game' class='alert-link'>Play again?</a>"
      @show_hit_or_stay_buttons = false
      halt erb(:end)
    elsif blackjack?(session[:player_cards])
      @win = "You hit blackjack! You win! <a href='/game' class='alert-link'>Play again?</a>"
      @show_hit_or_stay_buttons = false
      halt erb(:end)
    end
  end

  def check_dealer(dealer_cards)
    if bust?(session[:dealer_cards])
      @win = "The dealer busted! You win! <a href='/game' class='alert-link'>Play again?</a>"
      @show_hit_or_stay_buttons = false
      halt erb(:end)
    elsif blackjack?(session[:dealer_cards])
      @lose = "The dealer hit blackjack! Sorry, you lose! <a href='/game' class='alert-link'>Play again?</a>"
      @show_hit_or_stay_buttons = false
      halt erb(:end)
    end
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
  erb :new_player
end

post '/new_player' do
  if params[:player_name].empty?
    @error = "A name is required. Just enter something."
    halt erb(:new_player)
  end
  session[:player_name] = params[:player_name]
  redirect '/game'
end

get '/game' do
  suits = ['H', 'D', 'C', 'S']
  values = [2, 3, 4, 5, 6, 7, 8, 9, 10, 'J', 'Q', 'K', 'A']
  session[:deck] = suits.product(values).shuffle!
  session[:dealer_cards] = []
  session[:player_cards] = []
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  session[:player_status] = "playing"
  session[:dealer_status] = "playing"
  check_player(session[:player_cards])
  check_dealer(session[:dealer_cards])
  erb :game
end

post '/game/player/hit' do
  session[:player_cards] << session[:deck].pop
  check_player(session[:player_cards])
  erb :game
end

post '/game/player/stay' do
  @info = "You chose to stay. It's now the dealer's turn."
  @show_hit_or_stay_buttons = false
  session[:player_status] = "finished"
  erb :game
end

post '/game/dealer/move' do
  @show_hit_or_stay_buttons = false
  if (calculate_value_of_hand(session[:dealer_cards]) >= 17) && 
     (calculate_value_of_hand(session[:dealer_cards]) < 21)
    session[:dealer_status] = "finished"
  elsif 
    session[:dealer_cards] << session[:deck].pop
  end
  
  check_dealer(session[:dealer_cards])

  if session[:dealer_status] == "finished"
    @dealer_status = "The dealer has decided to stay."
  elsif session[:dealer_status] == "playing"
    @dealer_status = "The dealer decided to hit."
  end

  erb :game
end

get '/end' do
  @show_hit_or_stay_buttons = false

  if (session[:player_status] == "finished") && (session[:dealer_status] == "finished")
    dealer_value = calculate_value_of_hand(session[:dealer_cards])
    player_value = calculate_value_of_hand(session[:player_cards])
    if player_value > dealer_value
      @win = "You beat the dealer #{player_value} to #{dealer_value}! You win! <a href='/game' class='alert-link'>Play again?</a>"
    elsif dealer_value > player_value
      @lose = "The dealer beat you #{dealer_value} to #{player_value}! Sorry, you lose! <a href='/game' class='alert-link'>Play again?</a>"
    else
      @win = "Woah! It's a tie at #{dealer_value} to #{player_value}! <a href='/game' class='alert-link'>Play again?</a>"
    end
  end
  erb :end
end