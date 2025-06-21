{{
  config(
    materialized='view',
    tags=['staging']
  )
}}

WITH source AS (
    SELECT * FROM {{ source('raw', 'brands') }}
),

cleaned AS (
    SELECT
        brand_id,
        TRIM(brand_name) as brand_name,
        TRIM(website) as website,
        TRIM(description) as description,
        created_at,
        updated_at,
        -- Validação de website
        CASE 
            WHEN website ~* '^https?://[^\s/$.?#].[^\s]*$' THEN true 
            ELSE false 
        END as is_valid_website,
        -- Nome da marca padronizado
        INITCAP(TRIM(brand_name)) as standardized_brand_name,
        -- Flag para marcas ativas
        CASE 
            WHEN brand_name IS NOT NULL AND TRIM(brand_name) != '' THEN true 
            ELSE false 
        END as is_active_brand
    FROM source
    WHERE brand_id IS NOT NULL
)

SELECT * FROM cleaned 