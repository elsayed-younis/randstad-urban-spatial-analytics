with source as (
    select * from {{ source('bronze_raw', 'raw_places_randstad') }}
),

renamed_and_transformed as (
    select
        place_id,
        coalesce(place_name, 'Unnamed Facility') as place_name,
        coalesce(primary_category, 'general_service') as raw_category,
        lon,
        lat,
        geom,
        -- تصنيف المرافق إلى ركائز الوصول الحضري المستدام
        case 
            when primary_category ilike any ('%hospital%', '%clinic%', '%health%', '%pharmacy%') then 'Healthcare'
            when primary_category ilike any ('%school%', '%university%', '%college%', '%kindergarten%') then 'Education'
            when primary_category ilike any ('%station%', '%transit%', '%bus%', '%metro%', '%subway%') then 'Public Transit'
            when primary_category ilike any ('%supermarket%', '%grocery%', '%market%', '%mall%') then 'Daily Retail'
            else 'Other Amenities'
        end as amenity_pillar
    from source
    where geom is not null
)

select * from renamed_and_transformed