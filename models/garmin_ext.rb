class GarminConnect::Activity
  def conditions(wunderground: nil, stats: [:temp, :hum])
    local_pws = wunderground.nearby_pws(self.latlong)
    metrics = self.metrics
    info = metrics.each_with_index.map do |m, i|
      if (latlong = m.latlong) == [0.0, 0.0]
        j = i
        j -= 1 until (latlong = metrics[j].latlong) != [0.0, 0.0]
      end
      wunderground.closest_pws(latlong)
    end
    # puts info.length
    # puts metrics.length
    pws_list = info.uniq
    readings = Hash[pws_list.map{ |pws| [pws.id, pws.get_readings(metrics.shift.time, wunderground)] }]
    current_reading = readings[info.first.id].shift
    c_d = Hash.new { |hash, key| hash[key] = [] }
    # puts readings.first.inspect
    # puts info.first.class
    metrics.zip(info).map do |m, i|
      # puts readings[i].first.time
      current_reading = readings[i.id].shift until readings[i.id].first.time > m.time
      m.reading = current_reading
      stats.each { |stat| c_d[stat] << m.reading.send(stat) }
    end
    avg = Hash[c_d.map{ |k, arr| [k, (arr.inject(:+) / metrics.length).round(1)] }]
    # temp_avg = (c_d[:temp].inject(:+) / metrics.length).round(1)
    # hum_avg  = (c_d[:hum].inject(:+) / metrics.length).round(1)
    {
      temp:       avg[:temp],
      temp_max:   c_d[:temp].max,
      temp_min:   c_d[:temp].min,
      hum:        avg[:hum],
      stations:   pws_list.map{ |pws| pws.id }.uniq}
  end
  def summary(arr_of_symbols: %i{})
    {
      run_id:         self.activityId,
      time:           self.time,
      timestamp:      self.activitySummary.BeginTimestamp.display,
      distance:       self.distance,
      pace_secs:      self.pace_secs,
      avg_hr:         self.avg_hr,
      dur_secs:       self.dur_secs
    }.merge(Hash[arr_of_symbols.map{ |sym| [sym, self.send(sym)] }])
  end
end
class GarminConnect::Metric
  def pws
    @pws ||= Wunderground::PWS.closest(self.latlong)
  end
  def reading
    @reading
  end
  def reading=(reading)
    @reading = reading
  end
  def temp
    self.reading.temp
  end
  def hum
    self.reading.hum.to_f
  end

end



