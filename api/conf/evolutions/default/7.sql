# Add rating colour functions

# --- !Ups

CREATE TABLE colours (
    level integer,
    red integer,
    green integer,
    blue integer,
    CONSTRAINT level_key PRIMARY KEY(level)
);

INSERT INTO colours VALUES (0, 110, 32, 32);
INSERT INTO colours VALUES (1, 227, 59, 59);
INSERT INTO colours VALUES (2, 255, 166, 0);
INSERT INTO colours VALUES (3, 255, 250, 94);
INSERT INTO colours VALUES (4, 48, 219, 60);
INSERT INTO colours VALUES (5, 22, 105, 28);

CREATE OR REPLACE FUNCTION blend(start_val integer, end_val integer, ratio double precision)
RETURNS integer AS $$
BEGIN
	RETURN ROUND(start_val + (end_val - start_val) * ratio);;
END;;
$$ LANGUAGE plpgsql;


CREATE TYPE rgb as (r int, g int, b int);
CREATE OR REPLACE FUNCTION ratingColour(rating double precision)
RETURNS TABLE (t text) AS $$
BEGIN
  RETURN QUERY
    WITH
        startVal AS
            (SELECT CASE
                 WHEN rating < 1.8 THEN (SELECT (c.red, c.green, c.blue)::rgb FROM colours c WHERE level = 0)
                 WHEN rating < 2.6 THEN (SELECT (c.red, c.green, c.blue)::rgb FROM colours c WHERE level = 1)
                 WHEN rating < 3.4 THEN (SELECT (c.red, c.green, c.blue)::rgb FROM colours c WHERE level = 2)
                 WHEN rating < 4.2 THEN (SELECT (c.red, c.green, c.blue)::rgb FROM colours c WHERE level = 3)
                 ELSE (SELECT (c.red, c.green, c.blue)::rgb FROM colours c WHERE level = 4)
            END),
        endVal AS
            (SELECT CASE
                 WHEN rating < 1.8 THEN (SELECT (c.red, c.green, c.blue)::rgb FROM colours c WHERE level = 1)
                 WHEN rating < 2.6 THEN (SELECT (c.red, c.green, c.blue)::rgb FROM colours c WHERE level = 2)
                 WHEN rating < 3.4 THEN (SELECT (c.red, c.green, c.blue)::rgb FROM colours c WHERE level = 3)
                 WHEN rating < 4.2 THEN (SELECT (c.red, c.green, c.blue)::rgb FROM colours c WHERE level = 4)
                 ELSE (SELECT (c.red, c.green, c.blue)::rgb FROM colours c WHERE level = 5)
            END),
        normRating AS
            (SELECT CASE
                 WHEN rating < 1.8 THEN (rating - 1) / 0.8
                 WHEN rating < 2.6 THEN (rating - 1.8) / 0.8
                 WHEN rating < 3.4 THEN (rating - 2.6) / 0.8
                 WHEN rating < 4.2 THEN (rating - 3.4) / 0.8
                 ELSE (rating - 4.2) / 0.8
            END),
        red AS (SELECT blend((SELECT * FROM startVal).r, (SELECT * from endVal).r, (SELECT * FROM normRating))),
        green AS (SELECT blend((SELECT * from startVal).g, (SELECT * from endVal).g, (SELECT * FROM normRating))),
        blue AS (SELECT blend((SELECT * from startVal).b, (SELECT * from endVal).b, (SELECT * FROM normRating)))
        Select '#' || lpad(to_hex(re.blend), 2, '0') || lpad(to_hex(gr.blend), 2, '0') || lpad(to_hex(bl.blend), 2, '0')
        FROM (SELECT * FROM red) as re, (SELECT * FROM green) as gr, (SELECT * FROM blue) as bl;;
END;;
$$ LANGUAGE plpgsql;

	# --- !Downs

DROP TABLE colours;
DROP FUNCTION blend(integer, integer, double precision);
DROP TYPE rgb;
DROP FUNCTION ratingColour(double precision);
