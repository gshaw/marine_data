require "nokogiri"
require "open-uri"
require "json"

# Download the HTML
url = "https://www.ndbc.noaa.gov/data/5day2/"
puts "Fetching active weather buoys..."
html = URI.open(url).read

# Parse the HTML
doc = Nokogiri::HTML(html)

# Process the data
stations = {}

doc.css("a").each do |link|
  href = link["href"]
  if href =~ /^(\w+)_5day\.(\w+)$/
    station_id = $1
    kind = $2
    stations[station_id] ||= { id: station_id, kinds: [] }
    stations[station_id][:kinds] << kind unless stations[station_id][:kinds].include?(kind)
  end
end

# Convert to array and output as JSON
stations_array = stations.values

# Write to JSON file
filename = "data/weather_buoys_active.json"
File.write(filename, JSON.pretty_generate(stations_array))
puts "Wrote #{stations_array.count} records to #{filename}"
