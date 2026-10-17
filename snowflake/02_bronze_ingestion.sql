-- Randstad Urban Spatial Analytics | Bronze raw ingestion (Randstad bbox)
-- Author: Elsayed Younis | Source: Overture Maps 2026-08-19.0 | Oct 2026

CREATE OR REPLACE TABLE EURO_URBAN_DW.BRONZE_RAW.raw_buildings_randstad AS
SELECT
    $1:id::string                AS building_id,
    $1:subtype::string           AS building_type,
    $1:class::string             AS building_class,
    $1:names:primary::string     AS building_name,
    $1:bbox:minx::float          AS min_lon,
    $1:bbox:miny::float          AS min_lat,
    $1:bbox:maxx::float          AS max_lon,
    $1:bbox:maxy::float          AS max_lat,
    TO_GEOMETRY($1:geometry)     AS geom
FROM @EURO_URBAN_DW.BRONZE_RAW.overture_s3_stage/theme=buildings/type=building/
WHERE $1:bbox:minx BETWEEN 4.10 AND 5.30
  AND $1:bbox:maxx BETWEEN 4.10 AND 5.30
  AND $1:bbox:miny BETWEEN 51.80 AND 52.50
  AND $1:bbox:maxy BETWEEN 51.80 AND 52.50;

CREATE OR REPLACE TABLE EURO_URBAN_DW.BRONZE_RAW.raw_roads_randstad AS
SELECT
    $1:id::string            AS road_id,
    $1:class::string         AS road_class,
    TO_GEOMETRY($1:geometry) AS geom
FROM @EURO_URBAN_DW.BRONZE_RAW.overture_s3_stage/theme=transportation/type=segment/
WHERE $1:bbox:minx BETWEEN 4.10 AND 5.30
  AND $1:bbox:maxx BETWEEN 4.10 AND 5.30
  AND $1:bbox:miny BETWEEN 51.80 AND 52.50
  AND $1:bbox:maxy BETWEEN 51.80 AND 52.50;

CREATE OR REPLACE TABLE EURO_URBAN_DW.BRONZE_RAW.raw_places_randstad AS
SELECT
    $1:id::string                AS place_id,
    $1:names:primary::string     AS place_name,
    $1:categories:main::string   AS primary_category,
    $1:geometry:coordinates[0]::float AS lon,
    $1:geometry:coordinates[1]::float AS lat,
    TO_GEOMETRY($1:geometry)     AS geom
FROM @EURO_URBAN_DW.BRONZE_RAW.overture_s3_stage/theme=places/type=place/
WHERE $1:geometry:coordinates[0] BETWEEN 4.10 AND 5.30
  AND $1:geometry:coordinates[1] BETWEEN 51.80 AND 52.50;
