FROM ubuntu:16.04

RUN apt-get update
RUN apt-get install -y wget

WORKDIR /opt/t-rex

RUN wget https://github.com/pka/t-rex/releases/download/v0.7.2/t-rex-v0.7.2-x86_64-unknown-linux-gnu.tar.gz && tar xvf t-rex*

ADD config.toml config.toml

CMD ["/opt/t-rex/t_rex", "serve", "--config=/opt/t-rex/config.toml"]
