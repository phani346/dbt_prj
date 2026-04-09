{{ config(
    materialized='incremental',
    unique_key=['customer_id','valid_from'],
    incremental_strategy='merge'
) }}

with source as (

    select
        id as customer_id,
        name,
        city,
        current_timestamp as updated_at
    from {{ source('ecom', 'raw_customers') }}

),

existing as (

    {% if is_incremental() %}

        select *
        from {{ this }}

    {% else %}

        select
            null as customer_id,
            null as name,
            null as city,
            null as valid_from,
            null as valid_to,
            null as is_current
        where false

    {% endif %}

),

unioned as (

    -- combine old + new
    select
        customer_id,
        name,
        city,
        valid_from,
        valid_to,
        is_current
    from existing

    union all

    select
        customer_id,
        name,
        city,
        updated_at as valid_from,
        null as valid_to,
        true as is_current
    from source

),

ranked as (

    select *,
        row_number() over (
            partition by customer_id
            order by valid_from desc
        ) as rn
    from unioned

),

final as (

    select
        customer_id,
        name,
        city,
        valid_from,

        case 
            when rn = 1 then null
            else valid_from
        end as valid_to,

        case 
            when rn = 1 then true
            else false
        end as is_current

    from ranked
)

select * from final