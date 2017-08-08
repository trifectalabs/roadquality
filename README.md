# Road Quality
## Crowdsourced road quality data for cyclists

[roadquality.org](http://www.roadquality.org)

### Development
To compile server components:

    sbt api/compile

To run server locally:

    sbt "api/run -Dhttp.port=9001"
    sbt web/run

To compile web assets:

    cd web/
    elm make src/Main.elm --output=public/javascripts/main.js
    elm-css src/Stylesheets.elm --output=public/stylesheets/main.css

To run OSRM locally:

    # Get OSM data
    cd resources/maps
    curl -LO http://download.geofabrik.de/north-america/canada/ontario-latest.osm.pbf
    cd ..

    # Prepare data for routing
    docker run -t -v $(pwd)/maps:/data -v $(pwd)/profiles:/opt osrm/osrm-backend osrm-extract -p /opt/bicycle.lua /data/ontario-latest.osm.pbf
    docker run -t -v $(pwd)/maps:/data osrm/osrm-backend osrm-contract /data/ontario-latest.osrm

    # Run routing server
    docker run -t -i -p 5000:5000 -v $(pwd)/maps:/data osrm/osrm-backend osrm-routed /data/ontario-latest.osrm
