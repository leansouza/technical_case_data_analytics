-- Example of a custom dbt test
-- This test verifies that the total amount in orders matches the sum of the order items

-- Teste para validar se os totais dos pedidos correspondem aos itens
WITH order_totals AS (
    SELECT
        o.order_id,
        o.total_amount as order_total,
        SUM(oi.total_price) as calculated_total
    FROM {{ ref('stg_orders') }} o
    LEFT JOIN {{ ref('stg_order_items') }} oi ON o.order_id = oi.order_id
    GROUP BY o.order_id, o.total_amount
)

SELECT 
    order_id,
    order_total,
    calculated_total,
    ABS(order_total - calculated_total) as difference
FROM order_totals
WHERE ABS(order_total - calculated_total) > 0.01
