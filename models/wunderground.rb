require 'haversine'
require 'time'
require 'json'

class Wunderground
  # attr_reader *%i{key api_limit api_calls}
  # def initialize(api_key: ENV['wunderground_api_key'], api_limit: 10, api_calls: [])
  #   @key          = api_key
  #   @api_limit    = api_limit
  #   @api_calls    = api_calls
  #   @nearby_pws   = nil
  #   @closest_pws  = nil
  # end
  def api_key
    @api_key
  end
  def closest_pws(lat = nil, lon = nil)
    return @closest_pws unless (lat || @closest_pws)
    latlong = lon ? [lat.to_f, lon.to_f] : lat.map(&:to_f)
    @closest_pws = self.nearby_pws(latlong).min_by{ |pws| pws.distance(latlong) }
  end
  def nearby_pws(lat = nil, lon = nil)
    return @nearby_pws if @nearby_pws
    latlong = lon ? [lat.to_f, lon.to_f] : lat.map(&:to_f)
    url = "geolookup/q/#{latlong.join(',')}.json" # 37.776289,-122.395234
    json = self.request url
    @nearby_pws = PWS::init_multiple(json['location']['nearby_weather_stations']['pws']['station'])
  end
  def request(url)
    base = "http://api.wunderground.com/api/#{self.key}/"
    if self.calls.length == self.limit
      wait = 61 - (Time.now - self.calls.shift)
      sleep wait if wait > 0
    end
    self.calls << Time.now
    self.save if self.respond_to? :save
    JSON.parse(Net::HTTP.get(URI (base + url)))
  end
  class PWS
    attr_reader :data
    @@pws_blacklist = %w{Brichta ProweatherStation} # switch to IDs
    @@pws_blacklist = %w{KAZTUCSO217} # switch to IDs
    # @@list = []
    def initialize(hash)
      @data = hash
    end
    def method_missing(method, *args)
      @data[method.to_s]
    end
    def distance(lat, lon = nil)
      latlong = lon ? [lat.to_f, lon.to_f] : lat.map(&:to_f)
      Haversine.distance(latlong, [self.lat, self.lon])
    end
    def readings(time = nil)
      @readings
    end
    def get_readings(time, wunderground = self.class.new)
      url = "history_#{time.strftime('%Y%m%d')}/q/pws:#{self.id}.json"
      begin
        @readings = wunderground.request(url)['history']["observations"].map { |hash| Reading.new(hash) }
      rescue
        puts wunderground.request(url).keys.inspect
      end
    end

    class << self
      # def list
      #   @@list
      # end
      def closest(lat, lon = nil, list)
        latlong = lon ? [lat.to_f, lon.to_f] : lat.map(&:to_f)
        list.min_by{ |pws| pws.distance(latlong) }
      end
      def init_multiple(arr_of_pws, lat = nil, lon = nil, pws_blacklist = @@pws_blacklist)
        arr_of_pws.map { |hash| self.new(hash) }.reject{ |pws| pws_blacklist.include? pws.id}
      end
      def sort_distance(*latlong)
        self.list.sort_by! { |pws| pws.distance(latlong) }
      end
      def lookup(lat, lon = nil, wunderground_api_key = self.wunderground_api_key)
        latlong = lon ? [lat.to_f, lon.to_f] : lat.map(&:to_f)
        url = "http://api.wunderground.com/api/#{wunderground_api_key}/geolookup/q/#{latlong.join(',')}.json" # 37.776289,-122.395234
        json = JSON.parse(Net::HTTP.get(URI url))
        init_multiple(json['location']['nearby_weather_stations']['pws']['station'])
      end
      # def get_readings(time)
      #   self.list.first(5).each{ |pws| pws.get_readings(time) }
      # end
      def wunderground_api_key
        ENV['wunderground_api_key']
      end
    end
  end
  class Reading
    attr_reader :data
    def initialize(hash)
      @data = hash
    end
    def time
      Time.strptime(@data['date']['pretty'], '%I:%M %p %Z on %B %e, %Y')
    end
    def method_missing(method, *args)
      @data[method.to_s]
    end
    def temp
      @data['tempi'].to_f
    end
    def hum
      @data['hum'].to_f
    end
  end
end
