{{
  config(
    materialized='table',
    tags=['intermediate']
  )
}}

WITH brand_sales AS (
    SELECT
        b.brand_id,
        b.brand_name,
        b.standardized_brand_name,
        b.is_active_brand,
        COUNT(DISTINCT p.product_id) as total_products,
        COUNT(DISTINCT o.customer_id) as unique_customers,
        COUNT(DISTINCT o.order_id) as total_orders,
        SUM(o.total_amount) as total_revenue,
        SUM(o.discount_amount) as total_discounts,
        SUM(o.shipping_amount) as total_shipping,
        SUM(o.tax_amount) as total_tax,
        AVG(o.total_amount) as avg_order_value,
        COUNT(CASE WHEN o.order_status = 'completed' THEN 1 END) as completed_orders,
        COUNT(CASE WHEN o.order_status = 'cancelled' THEN 1 END) as cancelled_orders
    FROM {{ ref('stg_brands') }} b
    LEFT JOIN {{ ref('stg_products') }} p ON b.brand_id = p.brand_id
    LEFT JOIN {{ ref('stg_orders') }} o ON b.brand_id = o.brand_id
    GROUP BY b.brand_id, b.brand_name, b.standardized_brand_name, b.is_active_brand
),

brand_metrics AS (
    SELECT
        bs.*,
        -- Receita líquida
        bs.total_revenue - bs.total_discounts as net_revenue,
        -- Taxa de conversão
        CASE 
            WHEN bs.total_orders > 0 
            THEN (bs.completed_orders::float / bs.total_orders::float) * 100
            ELSE 0 
        END as conversion_rate,
        -- Taxa de cancelamento
        CASE 
            WHEN bs.total_orders > 0 
            THEN (bs.cancelled_orders::float / bs.total_orders::float) * 100
            ELSE 0 
        END as cancellation_rate,
        -- Receita por cliente
        CASE 
            WHEN bs.unique_customers > 0 
            THEN bs.total_revenue / bs.unique_customers
            ELSE 0 
        END as revenue_per_customer,
        -- Receita por produto
        CASE 
            WHEN bs.total_products > 0 
            THEN bs.total_revenue / bs.total_products
            ELSE 0 
        END as revenue_per_product,
        -- Taxa de desconto
        CASE 
            WHEN bs.total_revenue > 0 
            THEN (bs.total_discounts / bs.total_revenue) * 100
            ELSE 0 
        END as discount_rate,
        -- Performance score
        CASE 
            WHEN bs.total_revenue > 0 THEN 
                (bs.total_revenue * 0.4) + 
                (bs.unique_customers * 10 * 0.3) + 
                (bs.conversion_rate * 0.3)
            ELSE 0 
        END as performance_score
    FROM brand_sales bs
),

brand_segments AS (
    SELECT
        *,
        -- Segmentação por performance
        CASE 
            WHEN performance_score >= 10000 THEN 'Top Performer'
            WHEN performance_score >= 5000 THEN 'High Performer'
            WHEN performance_score >= 2000 THEN 'Medium Performer'
            WHEN performance_score >= 500 THEN 'Low Performer'
            ELSE 'Emerging'
        END as performance_segment,
        -- Segmentação por tamanho
        CASE 
            WHEN total_products >= 50 THEN 'Large Brand'
            WHEN total_products >= 20 THEN 'Medium Brand'
            WHEN total_products >= 5 THEN 'Small Brand'
            ELSE 'Micro Brand'
        END as size_segment
    FROM brand_metrics
)

SELECT * FROM brand_segments 