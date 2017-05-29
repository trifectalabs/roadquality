# Dockerfile for creating container with Tilestache 1.49

FROM ubuntu
MAINTAINER Christopher Poenaru <kiambogo@gmail.com>

ADD cache_expiry.py /cache_expiry.py

RUN apt-get update && apt-get install -y vim wget curl unzip

# Install Python + Pip
RUN apt-get install -y python-pip
RUN apt-get install -y autoconf apache2-dev libtool libxml2-dev libbz2-dev libgeos-dev libgeos++-dev libproj-dev gdal-bin libgdal1-dev mapnik-utils python-mapnik libmapnik-dev
# Install reqs for Tilestache
RUN pip install -U Pillow==2.6.1 modestmaps simplejson werkzeug uuid mapnik shapely

# Install Tilestache
RUN curl -o tilestache.tar.gz http://tilestache.org/download/TileStache-1.49.8.tar.gz
RUN tar xzf tilestache.tar.gz && cd TileStache-1.49.8 && python setup.py install && cd ../
RUN rm tilestache.tar.gz

# Install Carto
RUN curl -sL https://deb.nodesource.com/setup_6.x | bash - && apt-get install -y nodejs
RUN apt-get install -y nodejs
RUN npm install -g carto

# Install the Mapnik stylesheet
RUN mkdir -p /usr/local/src/MapBox/CustomPositron
WORKDIR /usr/local/src/MapBox
RUN wget https://github.com/mapbox/osm-bright/zipball/master && unzip master && rm master && mv mapbox*/* CustomPositron/
# Install the coastline data
RUN cd /usr/local/src/MapBox/CustomPositron && mkdir shp && cd shp && wget http://data.openstreetmapdata.com/simplified-land-polygons-complete-3857.zip && unzip simplified-land-polygons-complete-3857.zip
RUN cd /usr/local/src/MapBox/CustomPositron/shp && wget http://data.openstreetmapdata.com/land-polygons-split-3857.zip && unzip land-polygons-split-3857.zip
RUN cd /usr/local/src/MapBox/CustomPositron/shp && mkdir ne_10m_populated_places && cd ne* &&  wget http://www.naturalearthdata.com/http//www.naturalearthdata.com/download/10m/cultural/ne_10m_populated_places_simple.zip && unzip '*.zip'

ADD tilestache.cfg /tilestache.cfg
ADD configure.py /usr/local/src/MapBox/CustomPositron/
RUN cd CustomPositron && python configure.py && ./make.py
ADD palette.mss /usr/local/src/MapBox/CustomPositron
ADD roads.mss /usr/local/src/MapBox/CustomPositron
ADD project.mml /usr/local/src/MapBox/CustomPositron
RUN cd /usr/local/src/MapBox/CustomPositron && carto project.mml > mapnik.xml

# Write start script to start the expiration service and tilestache together
RUN echo """#!/bin/bash \n \
          python cache_expiry.py & \
          tilestache-server.py -i 0.0.0.0 -c /tilestache.cfg""" >> /start.sh
RUN chmod +x /start.sh

# Expose the Tilestache port
EXPOSE 8080

CMD ["/start.sh"]
