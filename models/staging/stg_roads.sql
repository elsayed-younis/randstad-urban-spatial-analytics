with source as (
    select * from {{ source('bronze_raw', 'raw_roads_randstad') }}
),

renamed_and_transformed as (
    select
        road_id,
        coalesce(road_subtype, 'road') as road_subtype,
        coalesce(road_class, 'unclassified') as road_class,
        coalesce(road_name, 'Unnamed Road') as road_name,
        min_lon,
        min_lat,
        max_lon,
        max_lat,
        geom,
        round(st_length(geom), 2) as road_length_m,
        case 
            when road_class in ('motorway', 'trunk') then 'High Capacity Corridor'
            when road_class in ('primary', 'secondary') then 'Major Urban Arterial'
            when road_class in ('tertiary', 'residential') then 'Local Access & Living'
            else 'Other / Pedestrian'
        end as functional_hierarchy
    from source
    where geom is not null
)

select * from renamed_and_transformed