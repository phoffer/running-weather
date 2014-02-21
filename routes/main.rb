class MyApp < Sinatra::Base
  before do
    @js = []
    @css = []
  end
  before do
    id = cookies[:id] || session[:id]
    # puts id
    if id && @user = User.find(id)
      @runs = @user.runs
    else
      # @user = nil
    end
    # puts @user.username
  end
  get '/' do
    @title = 'Running Weather'
    if @user
      haml :main
    else
      @var = 'nothing'
      haml :index
    end
  end
  get '/retrieve' do
    @run = @user.run(params[:run])
    haml :run
  end
  get '/runs' do
    # list all the runs
    haml :main
  end
  namespace '/run/:run_id' do
    before do
      @run = @user.run(params[:run_id])
      # @run = @user.run(params[:run])
    end
    get do
      # nothing
    end
    get '/weather' do
      @weather = @run.conditions
      # @weather = @run.conditions
    end
    after do
      if request.xhr?
        content_type 'application/json'
        @data = {user: @user, run: @run, weather: @weather}
        body @data.to_json if @data
      else
        body haml :run
      end
    end
  end
  post '/signup' do
    # allow sign up on main page? would make more sense
    # user sign up. only need garmin username
    # allow for
      # wunderground api key addition
      # pws
      # pws_bad
      # units (mi/km)
      # custom data (weather)
  end
  post '/login' do
    # if successful
    cookies[:id] = nil
    session.clear
    @user = User.find_by(name: params[:username])
    cookies[:id] = @user._id
    redirect '/'
    # 'something'.to_s
  end
  get '/logout' do
    session.clear
    cookies[:id] = nil
    redirect '/'
  end

end
