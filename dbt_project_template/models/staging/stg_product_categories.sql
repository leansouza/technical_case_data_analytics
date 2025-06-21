{{
  config(
    materialized='view',
    tags=['staging']
  )
}}

WITH source AS (
    SELECT * FROM {{ source('raw', 'product_categories') }}
),

cleaned AS (
    SELECT
        category_id,
        TRIM(category_name) as category_name,
        TRIM(description) as description,
        parent_category_id,
        created_at,
        updated_at,
        -- Nome da categoria padronizado
        INITCAP(TRIM(category_name)) as standardized_category_name,
        -- Flag para categorias ativas
        CASE 
            WHEN category_name IS NOT NULL AND TRIM(category_name) != '' THEN true 
            ELSE false 
        END as is_active_category,
        -- Nível da categoria (se tem parent ou não)
        CASE 
            WHEN parent_category_id IS NOT NULL THEN 'Subcategory'
            ELSE 'Main Category'
        END as category_level
    FROM source
    WHERE category_id IS NOT NULL
)

SELECT * FROM cleaned 