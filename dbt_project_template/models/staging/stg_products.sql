-- Example of a staging model for products
-- You can use this template to create your staging models

{{
  config(
    materialized='view',
    tags=['staging']
  )
}}

WITH source AS (
    SELECT * FROM {{ source('raw', 'products') }}
),

cleaned AS (
    SELECT
        product_id,
        TRIM(product_name) as product_name,
        TRIM(description) as description,
        price,
        cost,
        brand_id,
        category_id,
        is_active,
        created_at,
        updated_at,
        -- Cálculo de margem
        CASE 
            WHEN price > 0 AND cost > 0 
            THEN ((price - cost) / price) * 100
            ELSE NULL 
        END as margin_percentage,
        -- Flag para produtos ativos
        CASE 
            WHEN is_active = true AND price > 0 THEN true 
            ELSE false 
        END as is_available_for_sale,
        -- Categoria de preço
        CASE 
            WHEN price >= 100 THEN 'Premium'
            WHEN price >= 50 THEN 'Mid-Range'
            WHEN price >= 20 THEN 'Standard'
            ELSE 'Budget'
        END as price_category
    FROM source
    WHERE product_id IS NOT NULL
)

SELECT * FROM cleaned
