-- Randstad Urban Spatial Analytics | Distribution profiling + dashboard feed
-- Author: Elsayed Younis | Target: EURO_URBAN_DW.DBT_EYOUNIS | Oct 2026

SELECT
    fifteen_min_city_score AS score,
    COUNT(*)               AS hexagons
FROM EURO_URBAN_DW.DBT_EYOUNIS.fct_randstad_urban_grid
GROUP BY 1
ORDER BY 1 DESC;

SELECT
    amenity_pillar,
    COUNT(*) AS n
FROM EURO_URBAN_DW.DBT_EYOUNIS.stg_places
GROUP BY 1
ORDER BY 2 DESC;

SELECT
    h3_hex_id                       AS "h3_hex_id",
    fifteen_min_city_score          AS "score",
    urban_typology                  AS "typology",
    ST_ASGEOJSON(hex_boundary_geom) AS "geojson"
FROM EURO_URBAN_DW.DBT_EYOUNIS.fct_randstad_urban_grid
ORDER BY "score" DESC;
