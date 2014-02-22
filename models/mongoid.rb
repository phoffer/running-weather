class User
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  has_many :runs
  has_one :wunder, class_name: 'Wunderground'

  field :name,          type: String,                   as: :username   # garmin username
  field :service,       type: String,   default: 'garmin'
  field :zip,           type: Integer,  default: nil
  field :pws,           type: String,   default: nil
  field :pws_bad,       type: Array,    default: [],    as: :pws_blacklist
  field :unit,          type: String,   default: 'mi'
  field :custom,        type: Array,    default: []

  def target
    case self.service
    when 'garmin'
      GarminConnect::User.new(self.name)
    when 'runkeeper'
      # something for runkeeper
    end
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
    self.runs.find_or_create_by(run_id: run_id)
    # self.runs.create(run_id: run_id)
  end

  def method_missing(method, *args)
    if self.target.respond_to? method
      self.target.send(method, *args)
    end
  end
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
  embeds_one :condition, autobuild: true

  field :run_id,        type: String,     as: :activity_id
  field :service,       type: String,     default: 'something'
  field :time,          type: Time
  field :timestamp,     type: String
  field :distance,      type: Float
  field :pace_secs,     type: Integer
  field :avg_hr,        type: Integer,    default: nil
  field :dur_secs,      type: Integer


  before_create :copy_service
  after_create  do |run|
    self.retrieve_data
  end
  def copy_service
    self.service = self.user.service
  end
  def retrieve_data
    self.update_attributes(self.summary)
  end

  def duration
    Time.at(self.dur_secs).strftime("%M:%S")
  end
  def pace
    Time.at(self.pace_secs).strftime("%M:%S")
  end
  def target
    case self.service
    when 'garmin'
      GarminConnect::Activity.new(self.run_id)
    when 'runkeeper'
      # something for runkeeper
    end
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
