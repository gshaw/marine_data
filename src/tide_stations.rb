require "json"
require "net/http"
require "uri"

def titlecase(string)
  string.split(" ").map(&:capitalize).join(" ")
end

def sanitize_station_name(name)
  if name == name.upcase
    titlecase(name)
  else
    name
  end
end

geo_groups_url = "https://api.tidesandcurrents.noaa.gov/mdapi/prod/webapi/geogroups.json?type=ETIDES&lvl=4"
stations_url = "https://api.tidesandcurrents.noaa.gov/mdapi/prod/webapi/geogroups/%s/children.json"
all_stations = {}

puts "Fetching tide station groups..."
result = JSON.parse(Net::HTTP.get(URI(geo_groups_url)))

geo_group_list = result["geoGroupList"]
geo_group_list.each do |group|
  puts "Fetching tide stations in group id #{group["geoGroupId"]}..."
  stations_in_group = JSON.parse(Net::HTTP.get(URI(stations_url % group["geoGroupId"])))
  station_list = stations_in_group["stationList"]

  station_list.each do |station|
    next if station["stationId"].nil?

    station_id = station["stationId"]
    unless all_stations.key?(station_id)
      all_stations[station_id] = {
        "id" => station_id,
        "latitude" => station["lat"].to_f.round(5),
        "longitude" => station["lon"].to_f.round(5),
        "name" => sanitize_station_name(station["geoGroupName"])
      }
    end
  end
end

# Convert the hash to an array of stations
stations_array = all_stations.values


# Write to JSON file
filename = "data/tide_stations.json"
File.write(filename, JSON.pretty_generate(stations_array))
puts "Wrote #{stations_array.count} records to #{filename}"
