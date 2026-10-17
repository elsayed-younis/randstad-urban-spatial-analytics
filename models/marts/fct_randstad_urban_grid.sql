{{ config(
    materialized='table'
) }}

with buildings_stg as (
    select * from {{ ref('stg_buildings') }}
),

roads_stg as (
    select * from {{ ref('stg_roads') }}
),

places_stg as (
    select * from {{ ref('stg_places') }}
),

buildings_aggregated as (
    select
        h3_latlng_to_cell_string(st_y(centroid_geom), st_x(centroid_geom), 8) as h3_hex_id,
        count(building_id) as total_buildings,
        round(sum(footprint_area_sqm), 2) as total_footprint_sqm,
        round(avg(footprint_area_sqm), 2) as avg_building_footprint_sqm,
        count(case when building_class = 'residential' then 1 end) as residential_buildings_count,
        count(case when building_class = 'commercial' then 1 end) as commercial_buildings_count
    from buildings_stg
    where centroid_geom is not null
    group by 1
),

roads_aggregated as (
    select
        h3_latlng_to_cell_string(st_y(st_centroid(geom)), st_x(st_centroid(geom)), 8) as h3_hex_id,
        count(road_id) as total_road_segments,
        round(sum(road_length_m) / 1000.0, 2) as total_road_length_km,
        round(sum(case when functional_hierarchy = 'High Capacity Corridor' then road_length_m else 0 end) / 1000.0, 2) as highway_corridors_km,
        round(sum(case when functional_hierarchy = 'Major Urban Arterial' then road_length_m else 0 end) / 1000.0, 2) as arterial_roads_km,
        round(sum(case when functional_hierarchy = 'Local Access & Living' then road_length_m else 0 end) / 1000.0, 2) as local_streets_km
    from roads_stg
    where geom is not null
    group by 1
),

places_aggregated as (
    select
        h3_latlng_to_cell_string(lat, lon, 8) as h3_hex_id,
        count(place_id) as total_amenities,
        count(case when amenity_pillar = 'Public Transit' then 1 end) as transit_stops_count,
        count(case when amenity_pillar = 'Healthcare' then 1 end) as healthcare_count,
        count(case when amenity_pillar = 'Education' then 1 end) as education_count,
        count(case when amenity_pillar = 'Daily Retail' then 1 end) as retail_count
    from places_stg
    where lat is not null and lon is not null
    group by 1
),

all_active_hexes as (
    select h3_hex_id from buildings_aggregated
    union
    select h3_hex_id from roads_aggregated
    union
    select h3_hex_id from places_aggregated
),

final_marts as (
    select
        grid.h3_hex_id,
        h3_cell_to_boundary(grid.h3_hex_id) as hex_boundary_geom,
        coalesce(b.total_buildings, 0) as total_buildings,
        coalesce(b.total_footprint_sqm, 0.0) as total_footprint_sqm,
        coalesce(b.avg_building_footprint_sqm, 0.0) as avg_building_footprint_sqm,
        coalesce(b.residential_buildings_count, 0) as residential_buildings,
        coalesce(b.commercial_buildings_count, 0) as commercial_buildings,
        coalesce(r.total_road_segments, 0) as total_road_segments,
        coalesce(r.total_road_length_km, 0.0) as total_road_length_km,
        coalesce(r.highway_corridors_km, 0.0) as highway_corridors_km,
        coalesce(r.arterial_roads_km, 0.0) as arterial_roads_km,
        coalesce(r.local_streets_km, 0.0) as local_streets_km,
        coalesce(p.total_amenities, 0) as total_amenities,
        coalesce(p.transit_stops_count, 0) as transit_stops,
        coalesce(p.healthcare_count, 0) as healthcare_facilities,
        coalesce(p.education_count, 0) as education_facilities,
        coalesce(p.retail_count, 0) as daily_retail_amenities,
        (
            case when coalesce(p.transit_stops_count, 0) > 0 then 25 else 0 end +
            case when coalesce(p.healthcare_count, 0) > 0 then 25 else 0 end +
            case when coalesce(p.education_count, 0) > 0 then 25 else 0 end +
            case when coalesce(p.retail_count, 0) > 0 then 25 else 0 end
        ) as fifteen_min_city_score,
        case
            when coalesce(b.total_buildings, 0) >= 50 and coalesce(p.transit_stops_count, 0) >= 2 then 'Dense Transit-Oriented Urban'
            when coalesce(b.total_buildings, 0) >= 20 then 'Suburban Residential Fabric'
            when coalesce(r.total_road_length_km, 0.0) > 0 then 'Transport Corridor / Rural Fringe'
            else 'Sparse / Open Space'
        end as urban_typology
    from all_active_hexes grid
    left join buildings_aggregated b on grid.h3_hex_id = b.h3_hex_id
    left join roads_aggregated r on grid.h3_hex_id = r.h3_hex_id
    left join places_aggregated p on grid.h3_hex_id = p.h3_hex_id
)

select * from final_marts