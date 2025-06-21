{{
  config(
    materialized='view',
    tags=['staging']
  )
}}

WITH source AS (
    SELECT * FROM {{ source('raw', 'order_items') }}
),

cleaned AS (
    SELECT
        order_item_id,
        order_id,
        product_id,
        quantity,
        unit_price,
        total_price,
        discount_amount,
        created_at,
        updated_at,
        -- Validações de negócio
        CASE 
            WHEN quantity > 0 THEN true 
            ELSE false 
        END as is_valid_quantity,
        CASE 
            WHEN unit_price >= 0 THEN true 
            ELSE false 
        END as is_valid_unit_price,
        -- Cálculo de valor líquido
        total_price - discount_amount as net_price,
        -- Percentual de desconto
        CASE 
            WHEN total_price > 0 
            THEN (discount_amount / total_price) * 100
            ELSE 0 
        END as discount_percentage,
        -- Flag para itens com desconto
        CASE 
            WHEN discount_amount > 0 THEN true 
            ELSE false 
        END as has_discount
    FROM source
    WHERE order_item_id IS NOT NULL
)

SELECT * FROM cleaned 