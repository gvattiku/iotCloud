require "kemal"
require "db"
require "sqlite3"
require "json"


# Open a connection to SQLite3
database_url = "sqlite3:./database.db"
db = DB.open database_url

# Check if table exists
table_exists = db.scalar "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='sensor_data'"

# Create the table if it does not exist
if table_exists == 0
  puts "Table does not exist. Creating one"

  db.exec "CREATE TABLE sensor_data (boat_id int, \
co2_ppm int, h20_ppm int, n02_ppm int, n20_ppm int, \
ch4_ppm int, nh4_ppm int, gps_lat float, gps_lng float)"
end

# Ensure to close the database connection
at_exit { db.close }


# Set up the UDP Server
server = UDPSocket.new
server.bind("0.0.0.0", 1234)


# Spawn a fiber (this is like a thread, but lighter)
spawn do

  # receive sensor data from boats
  loop do
    data, _client = server.receive(1024)

    parsed_data = JSON.parse(data)

    puts "Incoming Data. Inserting"

    args = [] of DB::Any

    args << parsed_data["boat_id"].as_i
    args << parsed_data["co2_ppm"].as_i
    args << parsed_data["h20_ppm"].as_i
    args << parsed_data["n02_ppm"].as_i
    args << parsed_data["n20_ppm"].as_i
    args << parsed_data["ch4_ppm"].as_i
    args << parsed_data["nh4_ppm"].as_i
    args << parsed_data["gps_lat"].as_f
    args << parsed_data["gps_lng"].as_f

    db.exec "INSERT INTO sensor_data values (?, ?, ?, ?, ?, ?, ?, ?, ?)", args
    puts "---"
  end
end


# Web Server routes
get "/" do
  sensor_count = 15
  render "src/views/index.ecr", "src/views/layout.ecr"
end

get "/table" do

  sensor_data = [] of Array(Int64 | Float64)

  db.query "SELECT * FROM sensor_data" do |rs|

    rs.each do
      record = [] of (Int64 | Float64)

      record << rs.read(Int64)
      record << rs.read(Int64)
      record << rs.read(Int64)
      record << rs.read(Int64)
      record << rs.read(Int64)
      record << rs.read(Int64)
      record << rs.read(Int64)
      record << rs.read(Float64)
      record << rs.read(Float64)

      sensor_data << record
    end
  end

  render "src/views/table.ecr", "src/views/layout.ecr"
end

Kemal.run
