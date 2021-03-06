class MyApp < Sinatra::Base
  before do
    @js = []
    @css = []
    id = session[:id] || cookies[:id]
    # puts id
    if id && @user = User.find(id)
      @runs = @user.runs
    else
      # @user = nil
    end
    # puts @user.username
  end
  get '/css/*.css' do
    # scss(request.path[0..-5].gsub('css/', 'sass/').to_sym)
    scss params[:splat].first.to_sym, views: settings.views + '/sass'
  end
  get '/' do
    @title = 'Running Weather'
    if @user
      @act_ids = @user.activity_ids(@run_count || 20, 1)
      @act_ids.first(3).reverse.each{ |run_id| @user.run(run_id).conditions }
      # js 'ZeroClipboard.min'
      haml :main
    else
      @var = 'nothing'
      haml :index
    end
  end
  get '/calendar' do
    @first = Date.parse("#{params[:year] || Time.now.year}-#{params[:month] || Time.now.month}-01")
    @calendar = Cal.new_monthly_calendar(@first.year, @first.month, start_week_on: Cal::MonthlyCalendar::DAY_NAMES[@user.start_week_on])
    @runs = @runs.select{ |run| (@calendar.first_day.date..@calendar.last_day.date).cover?(run.date) }
    @month_miles = @runs.select{ |run| (@first.to_time..@first.end_of_month.end_of_day).cover?(run.time) }.inject(0) {|n,run| n + run.distance }
    @days = @runs.group_by(&:date)
    @week_miles = @runs.group_by{|r| (r.date+@user.day_offset).cweek }.sort.map { |_, runs| runs.map(&:distance).inject(:+).round(2) }
    # @week_miles = @calendar.weeks.inject(0) { |m, week| week.days.inject(0) {|n, day|  } }
    haml :calendar
  end
  get '/retrieve' do
    @r = @user.run(params[:run])
    haml :run
  end
  get '/settings' do

    haml :settings
  end
  get '/id/:id' do |id|
    @r = @user.runs.find(id)
    haml :run
  end
  get '/runs' do
    # list all the runs
    haml :main
  end
  get '/runs/all' do
    @act_ids = @user.activity_ids(1000)
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
    @weather = @r.conditions
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
    # puts @user.inspect
    cookies[:id] = nil
    session[:id] = @user._id
    # puts session[:id]
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
