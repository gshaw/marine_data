# Marine Data

Publish marine weather buoys and tide stations as JSON.

## Example

```text
❯ make
Executing src/tide_stations.rb...
Fetching tide station groups...
Fetching tide stations in group id 1743...
Fetching tide stations in group id 1746...
Fetching tide stations in group id 1748...
Fetching tide stations in group id 1749...
Fetching tide stations in group id 1750...
Wrote 3304 records to data/tide_stations.json
------------------------
Executing src/weather_buoys.rb...
Fetching weather buoys with cameras...
Fetching weather buoy owners...
Fetching weather buoys...
Wrote 1890 records to data/weather_buoys.json
------------------------
Executing src/weather_buoys_active.rb...
Fetching active weather buoys...
Wrote 1037 records to data/weather_buoys_active.json
------------------------
```
