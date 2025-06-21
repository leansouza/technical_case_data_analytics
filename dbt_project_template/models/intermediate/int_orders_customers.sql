{{
  config(
    materialized='table',
    tags=['intermediate']
  )
}}

WITH orders_aggregated AS (
    SELECT
        customer_id,
        brand_id,
        COUNT(DISTINCT order_id) as total_orders,
        SUM(total_amount) as total_spent,
        AVG(total_amount) as avg_order_value,
        MIN(order_date) as first_order_date,
        MAX(order_date) as last_order_date,
        SUM(discount_amount) as total_discounts,
        COUNT(CASE WHEN order_status = 'completed' THEN 1 END) as completed_orders,
        COUNT(CASE WHEN order_status = 'cancelled' THEN 1 END) as cancelled_orders,
        COUNT(CASE WHEN order_status = 'processing' THEN 1 END) as processing_orders,
        COUNT(CASE WHEN order_status = 'shipped' THEN 1 END) as shipped_orders,
        SUM(shipping_amount) as total_shipping,
        SUM(tax_amount) as total_tax
    FROM {{ ref('stg_orders') }}
    GROUP BY customer_id, brand_id
),

customer_metrics AS (
    SELECT
        c.customer_id,
        c.first_name,
        c.last_name,
        c.email,
        c.full_name,
        c.city,
        c.state,
        c.standardized_country as country,
        c.brand_id,
        c.is_valid_email,
        oa.total_orders,
        oa.total_spent,
        oa.avg_order_value,
        oa.first_order_date,
        oa.last_order_date,
        oa.total_discounts,
        oa.completed_orders,
        oa.cancelled_orders,
        oa.processing_orders,
        oa.shipped_orders,
        oa.total_shipping,
        oa.total_tax,
        -- Cálculo de recência
        DATEDIFF('day', oa.last_order_date, CURRENT_DATE) as days_since_last_order,
        -- Segmentação por valor
        CASE 
            WHEN oa.total_spent >= 1000 THEN 'High Value'
            WHEN oa.total_spent >= 500 THEN 'Medium Value'
            WHEN oa.total_spent >= 100 THEN 'Low Value'
            ELSE 'New Customer'
        END as value_segment,
        -- Taxa de conversão
        CASE 
            WHEN oa.total_orders > 0 
            THEN (oa.completed_orders::float / oa.total_orders::float) * 100
            ELSE 0 
        END as conversion_rate,
        -- Taxa de cancelamento
        CASE 
            WHEN oa.total_orders > 0 
            THEN (oa.cancelled_orders::float / oa.total_orders::float) * 100
            ELSE 0 
        END as cancellation_rate,
        -- Valor médio de desconto
        CASE 
            WHEN oa.total_orders > 0 
            THEN oa.total_discounts / oa.total_orders
            ELSE 0 
        END as avg_discount_per_order
    FROM {{ ref('stg_customers') }} c
    LEFT JOIN orders_aggregated oa ON c.customer_id = oa.customer_id
)

SELECT * FROM customer_metrics
