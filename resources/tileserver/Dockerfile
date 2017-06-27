FROM ubuntu:16.04

RUN apt-get update
RUN apt-get install -y wget python
RUN apt-get update
RUN apt-get install -y python-pip

RUN pip install -U psycopg2

WORKDIR /opt/t-rex

RUN wget https://github.com/pka/t-rex/releases/download/v0.7.5/t-rex-v0.7.5-x86_64-unknown-linux-gnu.tar.gz && tar xvf t-rex*

ADD cache_expiry.py cache-expiry.py
ADD config.toml config.toml

# Write start script to start the expiration service and tileserver together
RUN echo """#!/bin/bash \n \
          python /opt/t-rex/cache-expiry.py >> cache_expiration.log & \
          ./t_rex serve --config=/opt/t-rex/config.toml""" >> /start.sh
RUN chmod +x /start.sh

# Expose the tileserver port
EXPOSE 8080

CMD ["/start.sh"]
