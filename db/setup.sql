alter table planet_osm_line add column source int4;
alter table planet_osm_line add column target int4;

select pgr_createTopology('planet_osm_line', 0.000001, 'way', 'osm_id');
select pgr_nodeNetwork('planet_osm_line', 0.000001, 'osm_id', 'way');
select pgr_createTopology('planet_osm_line_noded', 0.000001, 'way', 'id');

alter table planet_osm_line_noded add column name text, add column type text, add column oneway text, add column surface text, add column bicycle text;

update planet_osm_line_noded as new set name = case when old.name is null then old.ref else old.name end, type = old.highway, oneway = old.oneway, surface = old.surface, bicycle = old.bicycle from planet_osm_line as old where new.old_id = old.osm_id;

alter table planet_osm_line_noded add distance float8;

update planet_osm_line_noded set distance = ST_Length(way) / 1000;
