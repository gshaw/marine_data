require "cgi"
require "json"
require "net/http"
require "nokogiri"
require "open-uri"

def stripped_or_nil(value)
  stripped_value = value.strip
  stripped_value.empty? ? nil : stripped_value
end

def download(url)
  URI.open(url).read
end

def strip_html(html)
  escaped = CGI.unescapeHTML(html.to_s.gsub(/<.*?>/, " "))
    .gsub(" \.", "\.")
    .gsub("&nbsp;", " ")
    .gsub("\t", " ")
    .gsub(/\s+/, " ")
  stripped_or_nil(escaped)
end

def build_station_ids_with_buoy_cams
  puts "Fetching weather buoys with cameras..."
  kml_data = download("https://www.ndbc.noaa.gov/kml/buoycams_as_kml.php")

  # Parse the KML data
  doc = Nokogiri::XML(kml_data)

  # Find all Placemark name elements and extract station IDs
  station_ids = doc
    .xpath("//kml:Placemark/kml:name", "kml" => "http://earth.google.com/kml/2.2")
    .map(&:text)

  station_ids
end

def build_station_owners
  puts "Fetching weather buoy owners..."
  response = download("https://www.ndbc.noaa.gov/data/stations/station_owners.txt")

  owners = {}
  response.each_line do |line|
    line.strip!
    next if line.empty? || line.start_with?("#")

    # ## Station Owners file format is:
    # # OWNERCODE | OWNERNAME | COUNTRYCODE
    # A  |CaroCOOPS|US
    # AC |U.S. Army Corps of Engineers|US
    # AF |University of Alaska, Fairbanks|US

    data = line.split("|").map { |value| stripped_or_nil(value) }

    code = data[0]
    owners[code] = {
      name: data[1],
      countryCode: data[2]
    }
  end
  owners
end

def build_stations(station_ids_with_buoy_cams, owners)
  puts "Fetching weather buoys..."
  response = download("https://www.ndbc.noaa.gov/data/stations/station_table.txt")
  buoys = []
  response.each_line do |line|
    line.strip!
    next if line.empty? || line.start_with?("#")

    data = line.split("|").map { |value| stripped_or_nil(value) }

    # STATION_ID | OWNER | TTYPE | HULL | NAME | PAYLOAD | LOCATION | TIMEZONE | FORECAST | NOTE
    # 13009|PR|Atlas Buoy|PM-533|Lambada||8.000 N 38.000 W (8&#176;0'0" N 38&#176;0'0" W)|| |

    station_id = data[0].upcase
    has_buoy_cam = station_ids_with_buoy_cams.include?(station_id)

    location = data[6].to_s
    if location =~ /(\d+\.\d+)\s+([NS])\s+(\d+\.\d+)\s+([EW])/
      latitude = $2 == "N" ? $1.to_f : -$1.to_f
      longitude = $4 == "E" ? $3.to_f : -$3.to_f
    else
      puts "skipping invalid coordinate: " + line
      next
    end

    owner_code = data[1]
    owner = owners[owner_code]
    if owner == nil
      puts "skipping unknown owner: " + line
      next
    end

    forecasts = data[8].to_s.split

    note = strip_html(data[9].to_s)

    buoys << {
      id: station_id,
      latitude: latitude.round(5),
      longitude: longitude.round(5),
      name: data[4],
      ownerCode: owner_code,
      ownerName: owner[:name],
      ownerCountryCode: owner[:countryCode],
      hasBuoyCam: has_buoy_cam,
      type: data[2],
      hull: data[3],
      payload: data[5],
      forecasts: forecasts,
      note: note
    }
  end
  buoys
end

station_ids_with_buoy_cams = build_station_ids_with_buoy_cams
owners = build_station_owners
stations_array = build_stations(station_ids_with_buoy_cams, owners)

# Write to JSON file
json = JSON.pretty_generate(stations_array).gsub(/\[\s+\]/, "[]")

filename = "data/weather_buoys.json"
File.write(filename, json)
puts "Wrote #{stations_array.count} records to #{filename}"
