-- Teste para validar valores positivos em campos monetários
SELECT 
    order_id,
    total_amount,
    'total_amount should be positive' as test_description
FROM {{ ref('stg_orders') }}
WHERE total_amount < 0

UNION ALL

SELECT 
    order_item_id,
    total_price,
    'total_price should be positive' as test_description
FROM {{ ref('stg_order_items') }}
WHERE total_price < 0

UNION ALL

SELECT 
    product_id,
    price,
    'price should be positive' as test_description
FROM {{ ref('stg_products') }}
WHERE price < 0 