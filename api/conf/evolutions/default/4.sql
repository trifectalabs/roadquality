# Cache expiry table

# --- !Ups

CREATE TABLE IF NOT EXISTS tile_cache_expirations (
  bounds text NOT NULL,
  created_at timestamp with time zone NOT NULL,
  processed_at timestamp with time zone
  );

CREATE INDEX ON tile_cache_expirations (created_at);
CREATE INDEX ON tile_cache_expirations (processed_at);


# --- !Downs

DROP TABLE tile_cache_expirations;
