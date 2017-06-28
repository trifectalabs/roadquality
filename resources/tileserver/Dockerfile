FROM ubuntu:16.04

RUN apt-get update
RUN apt-get install -y wget

WORKDIR /opt/t-rex

RUN wget https://github.com/kiambogo/t-rex/releases/download/v0.7.6/t_rex

RUN chmod +x /opt/t-rex/t_rex

ADD config.toml config.toml

EXPOSE 8080

CMD ["/opt/t-rex/t_rex", "serve", "--config=/opt/t-rex/config.toml"]
