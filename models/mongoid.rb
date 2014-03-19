# require 'active_support/core_ext/class/subclasses' # to get subclasses of Account -> Garmin, Runkeeper, etc.
# define method for each subclass of what string they represent
# have Account search for whichever subclass responds to a string
# replace case statement in User#add_account with Account.for('type', **args)
# pattern referenced by Sandi Metz @ RoA 2014
# or just have it look up class that matches (by name) the string. string.capitalize || camelize


class Account # subclassed by account for each supported service
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  belongs_to :user_mongoid, class_name: 'User'
  has_many :runs

end
class User
  include Mongoid::Document
  include Mongoid::Timestamps
  has_many :accounts, inverse_of: :user_mongoid
  has_many :runs
  has_one :wunder, class_name: 'Wunderground'

  field :email,         type: String
  field :zip,           type: Integer,  default: nil
  field :pws,           type: String,   default: nil
  field :pws_bad,       type: Array,    default: [],    as: :pws_blacklist
  field :unit,          type: String,   default: 'mi'
  field :start_week_on, type: Integer,  default: 0
  field :custom,        type: Array,    default: []

  def day_offset
    1 - self.start_week_on
  end

  # separate into user object and account object, 1-n. then grabbing data is based on account
  # account contains all information required for account handling
  # all interaction with source service
  # field :current,     type: Account

  def add_account(params)
    puts 'adding account'
    type = case params.delete('service')
    when 'garmin'
      Garmin
    when 'runkeeper'
      # runkeeper account class
    end
    # puts 'before_create'
    # a = type.create(params)
    # puts 'after_create'
    # puts a.inspect
    self.accounts << type.create(params)
    self.save
    self.run.conditions
  end
  def current
    # puts 'current'
    self.accounts.desc(:created_at).first
  end
  def target
    self.current
  end

  def import(limit = 100, start = 1)
    limit = 9999 if limit == :all
    self.activity_ids(limit, start).map do |id|
      begin
        self.run(id)
      rescue
        puts id # means there is some problem with the GPX
      end
    end
  end
  def wunderground
    self.wunder || Wunderground.find_or_create_by(key: ENV['wunderground_api_key'])
  end
  # def add_run(run_id = most_recent.activityId)
  #   self.runs.create (self.target.activity(run_id).summary.merge(service: self.service))
  # end
  def run(run_id = self.most_recent.id)
    run_id ||= self.most_recent.id
    # puts run_id
    self.runs.find_or_create_by(run_id: run_id)
    # self.runs.create(run_id: run_id)
  end

  def method_missing(method, *args)
    if self.target.respond_to? method
      self.target.send(method, *args)
    end
  end
end

class Runkeeper < Account

  field :auth_key_or_something, type: String

end

class Garmin < Account
  include Mongoid::Document
  include Mongoid::Timestamps::Created

  field :name,  type: String, as: :username   # garmin username

  def user
    GarminConnect::User.new(self.name)
  end
  def service
    'garmin'
  end
  def activity(run_id)
    GarminConnect::Activity.new(run_id)
  end
  def activity_list(*args)
    self.user.activity_list(*args).select{ |json| json['activityType']['typeKey']['running'] }
  end
  def activity_ids(*args)
    self.activity_list(*args).map{ |hash| hash['activityId'] }
  end

  def activities(*args)
    self.activity_list(*args).map { |a| self.activity(a['activityId']) }
  end
  def method_missing(method, *args)
    if self.user.respond_to? method
      self.user.send(method, *args)
    end
  end
  alias :run :activity


end

class Wunderground
  include Mongoid::Document
  belongs_to :user

  field :key,         type: String,   default: nil
  field :limit,       type: Integer,  default: 10
  field :calls,       type: Array,    default: -> {Array.new}

  # def request(url)
  #   base = "http://api.wunderground.com/api/#{self.key}/"
  #   if self.calls.length == self.limit
  #     wait = 61 - (Time.now - self.calls.shift)
  #     puts "wait: #{wait}"
  #     sleep wait if wait > 0
  #   end
  #   self.calls << Time.now
  #   JSON.parse(Net::HTTP.get(URI (base + url)))
  # end
end

class Run
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  belongs_to :user
  belongs_to :account
  embeds_one :condition, autobuild: true

  field :run_id,        type: String,     as: :activity_id
  field :time_utc,      type: Time
  field :time_zone,     type: String
  field :timestamp,     type: String
  field :distance,      type: Float
  field :pace_secs,     type: Integer
  field :avg_hr,        type: Integer,    default: nil
  field :dur_secs,      type: Integer

  # add query for between(a,b) -> { a.to_timezone..b.to_timezone } # where do we get timezone from?
            # maybe just #all.select{} ?

  before_create :copy_service
  after_create  do |run|
    run.retrieve_data
  end
  after_save do |run|
    run.user.touch
  end
  def display
    str = "#{self.distance} @ #{self.pace} - #{self.avg_hr}"
    self.condition.exist? ? str << " - #{condition.temp}" : str
  end
  def time
    ActiveSupport::TimeWithZone.new(self.time_utc.utc, ActiveSupport::TimeZone.new(self.time_zone))
  end
  def copy_service
    # puts self.user.current.inspect
    self.account = self.user.current
  end
  def retrieve_data
    self.update_attributes(self.summary)
  end
  def service
    self.account.class
  end
  def date
    self.time.to_date
  end
  def date_str
    self.date.to_s
  end
  def duration
    format = self.dur_secs >= 3600 ? "%l:%M:%S" : "%M:%S"
    Time.at(self.dur_secs).strftime(format)
  end
  def pace
    Time.at(self.pace_secs).strftime("%M:%S")
  end
  def target
    self.account.run(self.run_id)
  end
  def conditions_hash
    self.target.conditions(wunderground: self.user.wunderground, stats: [:temp, :hum] + self.user.custom)
  end
  def conditions
    self.condition.summary
  end
  def add_condition
    # puts self.user.wunderground.inspect
    self.create_condition self.target.conditions(wunderground: self.user.wunderground, stats: [:temp, :hum] + self.user.custom)
  end
  def method_missing(method, *args)
    # if self.target.respond_to? method
      self.target.send(method, *args)
    # end
  end
end
class Condition
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  embedded_in :run

  field :pws,           type: Array,  default: [],  as: :stations
  field :temp,          type: Float
  field :temp_min,      type: Float
  field :temp_max,      type: Float
  field :hum,           type: Float
  field :custom,        type: Hash,   default: {}

  def exist?
    !self.pws.empty?
  end

  def summary
    self.update_attributes(self.run.conditions_hash) if self.pws.empty?
    {
      pws:        self.pws,
      temp:       self.temp,
      temp_min:   self.temp_min,
      temp_max:   self.temp_max,
      hum:        self.hum,
      custom:     self.custom
    }
  end

end
