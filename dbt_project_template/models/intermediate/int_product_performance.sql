{{
  config(
    materialized='table',
    tags=['intermediate']
  )
}}

WITH product_sales AS (
    SELECT
        p.product_id,
        p.product_name,
        p.brand_id,
        p.category_id,
        p.price,
        p.cost,
        p.margin_percentage,
        p.price_category,
        p.is_available_for_sale,
        COUNT(DISTINCT oi.order_id) as orders_count,
        SUM(oi.quantity) as total_quantity_sold,
        SUM(oi.total_price) as total_revenue,
        SUM(oi.discount_amount) as total_discounts,
        SUM(oi.net_price) as net_revenue,
        AVG(oi.quantity) as avg_quantity_per_order,
        AVG(oi.unit_price) as avg_unit_price,
        COUNT(DISTINCT o.customer_id) as unique_customers
    FROM {{ ref('stg_products') }} p
    LEFT JOIN {{ ref('stg_order_items') }} oi ON p.product_id = oi.product_id
    LEFT JOIN {{ ref('stg_orders') }} o ON oi.order_id = o.order_id
    GROUP BY 
        p.product_id, p.product_name, p.brand_id, p.category_id,
        p.price, p.cost, p.margin_percentage, p.price_category, p.is_available_for_sale
),

product_metrics AS (
    SELECT
        ps.*,
        -- Performance score baseado em receita, quantidade e margem
        CASE 
            WHEN ps.total_revenue > 0 THEN 
                (ps.total_revenue * 0.4) + 
                (ps.orders_count * 10 * 0.3) + 
                (COALESCE(ps.margin_percentage, 0) * 0.3)
            ELSE 0 
        END as performance_score,
        -- ROI (Return on Investment)
        CASE 
            WHEN ps.cost > 0 AND ps.total_quantity_sold > 0
            THEN ((ps.total_revenue - (ps.cost * ps.total_quantity_sold)) / (ps.cost * ps.total_quantity_sold)) * 100
            ELSE NULL 
        END as roi_percentage,
        -- Taxa de desconto média
        CASE 
            WHEN ps.total_revenue > 0 
            THEN (ps.total_discounts / ps.total_revenue) * 100
            ELSE 0 
        END as avg_discount_rate,
        -- Receita por cliente
        CASE 
            WHEN ps.unique_customers > 0 
            THEN ps.total_revenue / ps.unique_customers
            ELSE 0 
        END as revenue_per_customer,
        -- Segmentação de performance
        CASE 
            WHEN ps.performance_score >= 1000 THEN 'Top Performer'
            WHEN ps.performance_score >= 500 THEN 'High Performer'
            WHEN ps.performance_score >= 200 THEN 'Medium Performer'
            WHEN ps.performance_score >= 50 THEN 'Low Performer'
            ELSE 'Non-Performer'
        END as performance_segment
    FROM product_sales ps
)

SELECT * FROM product_metrics 