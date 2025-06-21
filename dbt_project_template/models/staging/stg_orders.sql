-- Example of a staging model for orders
-- You can use this template to create your staging models

{{
  config(
    materialized='view',
    tags=['staging']
  )
}}

WITH source AS (
    SELECT * FROM {{ source('raw', 'orders') }}
),

cleaned AS (
    SELECT
        order_id,
        customer_id,
        order_date,
        order_status,
        payment_method,
        total_amount,
        shipping_amount,
        tax_amount,
        discount_amount,
        currency,
        brand_id,
        created_at,
        updated_at,
        -- Validações de negócio
        CASE 
            WHEN total_amount >= 0 THEN true 
            ELSE false 
        END as is_valid_amount,
        CASE 
            WHEN order_date <= CURRENT_DATE THEN true 
            ELSE false 
        END as is_valid_date,
        -- Cálculo de valor líquido
        total_amount - discount_amount as net_amount,
        -- Flag para pedidos com desconto
        CASE 
            WHEN discount_amount > 0 THEN true 
            ELSE false 
        END as has_discount
    FROM source
    WHERE order_id IS NOT NULL
)

SELECT * FROM cleaned
