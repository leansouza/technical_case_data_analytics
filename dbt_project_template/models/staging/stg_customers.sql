-- Example of a staging model
-- You can use this template to create your staging models

{{
  config(
    materialized='view',
    tags=['staging']
  )
}}

WITH source AS (
    SELECT * FROM {{ source('raw', 'customers') }}
),

cleaned AS (
    SELECT
        customer_id,
        TRIM(first_name) as first_name,
        TRIM(last_name) as last_name,
        LOWER(TRIM(email)) as email,
        TRIM(city) as city,
        TRIM(state) as state,
        TRIM(country) as country,
        brand_id,
        created_at,
        updated_at,
        -- Validação de email
        CASE 
            WHEN email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' 
            THEN true 
            ELSE false 
        END as is_valid_email,
        -- Nome completo
        TRIM(first_name) || ' ' || TRIM(last_name) as full_name,
        -- País padronizado
        CASE 
            WHEN UPPER(country) IN ('USA', 'US', 'UNITED STATES') THEN 'USA'
            WHEN UPPER(country) IN ('CANADA', 'CA') THEN 'Canada'
            ELSE INITCAP(country)
        END as standardized_country
    FROM source
    WHERE customer_id IS NOT NULL
)

SELECT * FROM cleaned
