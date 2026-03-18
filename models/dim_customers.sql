{{config(
    materialized='incremental',
    unique_key ='id'
)}}

select id,name,city from {{source('ecom','raw_customers')}}