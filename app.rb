require 'sinatra'
require 'sinatra/reloader' if development?
require 'haml'

enable :sessions

get "/" do 
  new_game
  set_state
  haml :game, layout: :main
end

post "/" do
  guess = params['guess'].upcase
  process_guess(guess) if session[:misses] < 6
  game_status
  set_state
  haml :game, layout: :main
end

helpers do

  def set_state
    @solution_word = session[:solution_word]
    @solution_array = session[:solution_array]
    @misses = session[:misses]
    @guess_array = session[:guess_array]
    @failed_guesses = session[:failed_guesses]
    @letters = session[:letters]
    @message = session[:message]
  end
  
  def new_game
    session[:guess_array] = []
    session[:failed_guesses] = []
    session[:letters] = ('A'..'Z').to_a
    session[:message] = ""
    session[:misses] = 0
    session[:solution_array] = []
    session[:solution_word] = ""
    generate_word
  end

  def generate_word
    valid_word = false
    while valid_word == false
      wordlist = File.open('lib/5desk.txt', 'r')
      random_num = rand(wordlist.readlines.size)
      session[:solution_word] = File.readlines(wordlist)[random_num].strip.upcase
      valid_word = true if (5..12).to_a.include?(session[:solution_word].length)
    end
    wordlist.close
    session[:solution_word].length.times { session[:guess_array].push('_ ') }
    session[:solution_array] = session[:solution_word].split('')
    session[:solution_word]
  end

  def process_guess(guess)
    if validate_guess(guess) == true
      guess = guess[0].upcase
      if session[:solution_array].include?(guess)
        session[:solution_array].each_with_index do |letter, index|
          session[:guess_array][index] = guess if letter == guess
        end
      else
        session[:failed_guesses].push(guess)
        session[:letters].delete(guess)
        session[:misses] += 1
      end
    end
  end
    
  def validate_guess(guess)
    case
    when guess.nil? 
      session[:message] = "Please enter one letter of the alphabet!"
      false
    when guess == ""
      session[:message] = "Please enter one letter of the alphabet!"
      false
    when guess.length != 1
      session[:message] = "Please enter one letter of the alphabet!"
      false
    when !("A".."Z").to_a.include?(guess.upcase)
      session[:message] = "Please enter one letter of the alphabet!"
      false
    when guess.class != String
      session[:message] = "Please enter one letter of the alphabet!"
      false        
    when !session[:letters].include?(guess.upcase)
      session[:message] = "You already guessed that letter!"
      false
    else
      true
    end
  end

  def game_status
    if session[:misses] == 6
      session[:message] = "You LOST! The solution was #{session[:solution_word]}."
    elsif session[:guess_array] == session[:solution_array]
      session[:message] = "Congratulations -- You WON!!!"
    end
  end
end