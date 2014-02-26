class MyApp < Sinatra::Base
  before do
    @js = []
    @css = []
  end
  before do
    id = session[:id] || cookies[:id]
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
      js 'ZeroClipboard.min'
      haml :main
    else
      @var = 'nothing'
      haml :index
    end
  end
  get '/retrieve' do
    @r = @user.run(params[:run])
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
    @r = @user.run(params[:run_id])
    haml :run
  end
  get '/weather/:run_id' do
    @r = @user.run(params[:run_id])
    @weather = @run.conditions
    haml :run
  end
  get '/runkeeper' do
    if params[:code]
      # return from RK
    else
      # need to go to RK
    end
    haml :runkeeper
  end
  post '/wunderground' do
    # puts params[:limit].inspect
    if w = @user.wunder
      w.update_attributes(params)
    else
      @user.create_wunder(params)
    end
    redirect '/welcome'
  end
  post '/account' do
    @user.add_account(params)
    redirect '/welcome'
  end
  get '/welcome' do
    # only after first sign up or intentionally going back to this page. like setup
    haml :welcome
  end
  post '/signup' do
    @user = User.find_or_create_by(email: params[:email])
    puts @user.inspect
    cookies[:id] = nil
    session[:id] = @user._id
    puts session[:id]
    redirect '/welcome'
  end
  post '/login' do
    # if successful
    cookies[:id] = nil
    session.clear
    @user = User.find_by(email: params[:email])
    params[:remember] ? cookies[:id] = @user._id : session[:id] = @user._id
    redirect '/'
    # 'something'.to_s
  end
  get '/logout' do
    session.clear
    cookies[:id] = nil
    redirect '/'
  end

end
