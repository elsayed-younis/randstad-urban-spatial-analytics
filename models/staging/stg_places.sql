with source as (

    select * from {{ source('bronze_raw', 'raw_places_randstad') }}

),

classified as (

    select
        place_id,
        place_name,
        lon,
        lat,
        geom,
        case
            when place_name ilike any (
                '%ziekenhuis%', '%kliniek%', '%apotheek%', '%huisarts%',
                '%tandarts%', '%medisch%', '%zorg%', '%verpleeg%',
                '%hospital%', '%clinic%', '%pharmacy%', '%medical%',
                '%doctor%', '%dentist%', '%health%'
            ) then 'Healthcare'
            when place_name ilike any (
                '%school%', '%lyceum%', '%gymnasium%', '%universiteit%',
                '%hogeschool%', '%college%', '%kindergarten%',
                '%peuterspeel%', '%kinderdagverblijf%', '%bibliotheek%',
                '%education%', '%university%', '%academy%', '%library%'
            ) then 'Education'
            when place_name ilike any (
                '%station%', '%halte%', '%bushalte%', '%tramhalte%',
                '%metrostation%', '%trein%', '%pont%', '%veer%',
                '%bus%', '%tram%', '%metro%', '%ferry%',
                '%subway%', '%transit%', '%transport%'
            ) then 'Public Transit'
            when place_name ilike any (
                '%supermarkt%', '%winkel%', '%bakkerij%', '%slagerij%',
                '%markt%', '%jumbo%', '%albertijn%', '%albert heijn%',
                '%plus%', '%dirk%', '%lidl%', '%aldi%', '%picnic%',
                '%emte%', '%delicatessen%', '%grocery%', '%market%',
                '%convenience%', '%bakery%', '%butcher%', '%retail%'
            ) then 'Daily Retail'
            else 'Other Amenities'
        end as amenity_pillar
    from source
    where geom is not null

)

select * from classified