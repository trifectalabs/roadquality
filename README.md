# The Road Quality Project
### Crowdsourcing road quality and traffic safety data for cyclists

This project is not currently being maintained. If you are interested in it in any way please let us know and we'd love to talk to you about it!

## Demo

![RoadQuality GIF Demo](demo.gif)

Higher quality video of demo available at https://vimeo.com/241302056.

## Development
#### Prerequesties

1. Java 8
2. Scala 2.12
3. SBT
4. Elm 0.18
5. elm-css
6. Docker
7. Postgres
8. [Osmosis](http://wiki.openstreetmap.org/wiki/Osmosis#Downloading)
9. [PostGIS](http://postgis.net/install/)
10. [pgrouting](http://pgrouting.org/)
11. osm2pgrouting

#### To setup database locally:

```sh
# Assuming you have an .osm.pbf file from Geofabrik
# Use osmosis to select specific area
osmosis --read-pbf ./ontario-latest.osm.pbf --bounding-box top=43.753963 bottom=43.561912 left=-79.632868 right=-79.194903 --write-xml toronto.osm
# or just keep the entire area
osmosis --read-pbf ./ontario-latest.osm.pbf --write-xml ontario-latest.osm
# create maps database with trifecta user
createuser -s trifecta
createdb maps --user trifecta
# Setup postgis and pgrouting in the db
psql maps --user trifecta
> create extension postgis;
> create extension pgrouting;
# import osm data into db
osm2pgrouting --f toronto.osm --conf /usr/share/osm2pgrouting/mapconfig_for_bicycles.xml --dbname maps --clean
# note: on macOS if osm2pgrouting was installed with Homebrew the path for the config is /usr/local/Cellar/osm2pgrouting/2.2.0_2/share/osm2pgrouting/mapconfig_for_bicycles.xml
```

#### To compile server components:

```sh
sbt api/compile
```

#### To compile web assets:

```sh
cd web/
elm make src/Main.elm --output=public/javascripts/main.js
elm-css src/Stylesheets.elm --output=public/stylesheets/main.css
```

#### To run server locally:

You need the following environment variables

```sh
# if running osrm as stated below this can be set to http://localhost:5000
OSRM_URI
# at this point in time strava is the only auth service and as such strava client identifiers are required
STRAVA_CLIENT_ID
STRAVA_CLIENT_SECRET
# needs to exist for the application to run, but can be any string if mailing list signup is not required
MAILCHIMP_TOKEN
```

Note the first time the server is run it will setup the database. This however has one caveat at the moment as it does not add the "temporary" table `beta_user_whitelist`. 

```sh
psql maps --user trifecta
> create table beta_user_whitelist (email text);
> insert into beta_user_whitelist values ('your strava email address');
```

Run the server

```sh
sbt "api/run -Dhttp.port=9001"
sbt web/run
```

#### To run routing locally:

```sh
# Get OSM data
cd resources/osrm && mkdir maps && cd maps
curl -LO http://download.geofabrik.de/north-america/canada/ontario-latest.osm.pbf && cd ..
# Prepare data for routing
docker run -t -v $(pwd)/maps:/data -v $(pwd)/profiles:/opt osrm/osrm-backend osrm-extract -p /opt/bicycle.lua /data/ontario-latest.osm.pbf
docker run -t -v $(pwd)/maps:/data osrm/osrm-backend osrm-contract /data/ontario-latest.osrm
# Run routing server
docker run -t -i -p 5000:5000 -v $(pwd)/maps:/data osrm/osrm-backend osrm-routed /data/ontario-latest.osrm
```

#### To run tileserver locally:

```sh
# find docker ip address (172.16.123.1 on macOS)
sudo ifconfig lo0 alias 172.16.123.1 # macOS only
```

Update postgres to trust connections from the above address. Open your `pg_hba.conf` and add `host  all  all  172.16.123.1/32  trust`. Then start the docker container.

```sh
docker run -e TREX_DATASOURCE_URL=postgresql://trifecta@172.16.123.1/maps -p 8080:8080 --name trex kiambogo/roadquality_tileserver:0.2.2
```
