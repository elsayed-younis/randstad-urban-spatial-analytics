with source as (
    select * from {{ source('bronze_raw', 'raw_buildings_randstad') }}
),

renamed_and_transformed as (
    select
        building_id,
        coalesce(building_type, 'unclassified') as building_type,
        coalesce(building_class, 'general') as building_class,
        coalesce(building_name, 'Unknown') as building_name,
        min_lon,
        min_lat,
        max_lon,
        max_lat,
        geom,
        round(st_area(geom), 2) as footprint_area_sqm,
        st_centroid(geom) as centroid_geom
    from source
    where geom is not null
)

select * from renamed_and_transformed