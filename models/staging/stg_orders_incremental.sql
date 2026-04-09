{{ config(
    materialized='incremental',
    unique_key='order_id'
) }}

with source as (

    select * from {{ source('ecom', 'raw_orders') }}

),

deduplicated as (

    select *
    from (
        select *,
               row_number() over (
                   partition by id
                   order by updated_at desc
               ) as rn
        from source
    )
    where rn = 1

),

renamed as (

    select
        id as order_id,
        store_id as location_id,
        customer as customer_id,
        subtotal,
        tax_paid,
        order_total,
        updated_at
    from deduplicated

)

select * from renamed

{% if is_incremental() %}

where updated_at > (
    select coalesce(max(updated_at), '1900-01-01') from {{ this }}
)

{% endif %}