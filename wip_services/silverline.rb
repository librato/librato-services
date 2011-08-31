# encoding: utf-8
class Service::Silverline < Service
  def receive_logs
    values = Hash.new { |h,k| h[k] = 0 }

    payload[:events].each do |event|
      time = Time.parse(event[:received_at])
      time = time.to_i - (time.to_i % 60)
      values[time] += 1
    end

    gauges = values.collect do |time, count|
      {
        :name => settings[:name],
        :value => count,
        :measure_time => time
      }
    end

    http.basic_auth settings[:user], settings[:token]

    res = http_post 'https://metrics-api.librato.com/v1/metrics.json' do |req|
      req.headers[:content_type] = 'application/json'

      req.body = {
        :gauges => gauges
      }.to_json
    end
  end
end