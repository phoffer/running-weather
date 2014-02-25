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
  post '/run' do
    content_type 'application/plain'
    @r = @user.run(params[:run_id])
    haml :run_tr, layout: false
  end
  post '/weather' do
    content_type 'application/plain'
    @r = @user.run(params[:run_id])
    @weather = @r.conditions
    haml :run_tr, layout: false
  end

  get '/run/:run_id' do
    @run = @user.run(params[:run_id])
    body haml :run
  end
  get '/weather/:run_id' do
    @run = @user.run(params[:run_id])
    @weather = @run.conditions
    body haml :run
  end
  get '/runkeeper' do
    if params[:code]
      # return from RK
    else
      # need to go to RK
    end
    haml :runkeeper
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
