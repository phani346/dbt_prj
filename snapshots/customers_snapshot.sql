{% snapshot customers_snapshot%}

{{
    config(
        target_schema ='snapshots',
        unique_key ='id',
        strategy='check',
        check_cols=['name','city']
    )
}}

select id, name, city from {{source('ecom','raw_customers')}}
{% endsnapshot %}