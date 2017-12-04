require "socket"
require "json"


# Set up the client
client = UDPSocket.new
client.connect("0.0.0.0", 1234)


# Random sensors and readings
readings = {
  boat_id: rand(1..10),
  co2_ppm: rand(100..500),
  h20_ppm: rand(100..500),
  n02_ppm: rand(100..500),
  n20_ppm: rand(100..500),
  ch4_ppm: rand(100..500),
  nh4_ppm: rand(100..500),
  gps_lat: rand * 180,
  gps_lng: rand * 180
}

json = readings.to_json

begin
  client.send(json, 0)
rescue Exception => err
  puts err
end
