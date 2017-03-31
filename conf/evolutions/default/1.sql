# Segments schema

# --- !Ups

CREATE TABLE IF NOT EXISTS segments (
    id uuid NOT NULL,
    name varchar(255),
    description text,
    start_point geometry NOT NULL,
    end_point geometry NOT NULL,
    polyline text,
    PRIMARY KEY (id)
);

# --- !Downs

DROP TABLE IF EXISTS segments;
