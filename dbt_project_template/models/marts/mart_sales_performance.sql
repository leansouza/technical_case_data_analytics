{{
  config(
    materialized='table',
    tags=['marts']
  )
}}

WITH daily_sales AS (
    SELECT
        DATE(order_date) as sale_date,
        brand_id,
        COUNT(DISTINCT order_id) as orders_count,
        COUNT(DISTINCT customer_id) as unique_customers,
        SUM(total_amount) as total_revenue,
        SUM(shipping_amount) as total_shipping,
        SUM(tax_amount) as total_tax,
        SUM(discount_amount) as total_discounts,
        AVG(total_amount) as avg_order_value,
        COUNT(CASE WHEN order_status = 'completed' THEN 1 END) as completed_orders,
        COUNT(CASE WHEN order_status = 'cancelled' THEN 1 END) as cancelled_orders,
        COUNT(CASE WHEN order_status = 'processing' THEN 1 END) as processing_orders,
        COUNT(CASE WHEN order_status = 'shipped' THEN 1 END) as shipped_orders,
        -- Métricas por método de pagamento
        COUNT(CASE WHEN payment_method = 'credit_card' THEN 1 END) as credit_card_orders,
        COUNT(CASE WHEN payment_method = 'paypal' THEN 1 END) as paypal_orders,
        COUNT(CASE WHEN payment_method = 'debit_card' THEN 1 END) as debit_card_orders
    FROM {{ ref('stg_orders') }}
    GROUP BY DATE(order_date), brand_id
),

sales_metrics AS (
    SELECT
        sale_date,
        brand_id,
        orders_count,
        unique_customers,
        total_revenue,
        total_shipping,
        total_tax,
        total_discounts,
        avg_order_value,
        completed_orders,
        cancelled_orders,
        processing_orders,
        shipped_orders,
        credit_card_orders,
        paypal_orders,
        debit_card_orders,
        -- Receita líquida
        total_revenue - total_discounts as net_revenue,
        -- Taxa de conversão
        CASE 
            WHEN orders_count > 0 
            THEN (completed_orders::float / orders_count::float) * 100
            ELSE 0 
        END as conversion_rate,
        -- Taxa de cancelamento
        CASE 
            WHEN orders_count > 0 
            THEN (cancelled_orders::float / orders_count::float) * 100
            ELSE 0 
        END as cancellation_rate,
        -- Taxa de desconto
        CASE 
            WHEN total_revenue > 0 
            THEN (total_discounts / total_revenue) * 100
            ELSE 0 
        END as discount_rate,
        -- Receita por cliente
        CASE 
            WHEN unique_customers > 0 
            THEN total_revenue / unique_customers
            ELSE 0 
        END as revenue_per_customer,
        -- Receita por pedido
        CASE 
            WHEN orders_count > 0 
            THEN total_revenue / orders_count
            ELSE 0 
        END as revenue_per_order
    FROM daily_sales
),

rolling_metrics AS (
    SELECT
        *,
        -- Média móvel de 7 dias
        AVG(total_revenue) OVER (
            PARTITION BY brand_id 
            ORDER BY sale_date 
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ) as revenue_7d_avg,
        AVG(orders_count) OVER (
            PARTITION BY brand_id 
            ORDER BY sale_date 
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ) as orders_7d_avg,
        -- Média móvel de 30 dias
        AVG(total_revenue) OVER (
            PARTITION BY brand_id 
            ORDER BY sale_date 
            ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
        ) as revenue_30d_avg,
        AVG(orders_count) OVER (
            PARTITION BY brand_id 
            ORDER BY sale_date 
            ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
        ) as orders_30d_avg,
        -- Crescimento vs período anterior
        LAG(total_revenue, 1) OVER (
            PARTITION BY brand_id 
            ORDER BY sale_date
        ) as previous_day_revenue,
        LAG(orders_count, 1) OVER (
            PARTITION BY brand_id 
            ORDER BY sale_date
        ) as previous_day_orders
    FROM sales_metrics
),

growth_metrics AS (
    SELECT
        *,
        -- Crescimento de receita diário
        CASE 
            WHEN previous_day_revenue > 0 
            THEN ((total_revenue - previous_day_revenue) / previous_day_revenue) * 100
            ELSE NULL 
        END as daily_revenue_growth,
        -- Crescimento de pedidos diário
        CASE 
            WHEN previous_day_orders > 0 
            THEN ((orders_count - previous_day_orders) / previous_day_orders) * 100
            ELSE NULL 
        END as daily_orders_growth,
        -- Performance score
        CASE 
            WHEN total_revenue > 0 THEN 
                (total_revenue * 0.4) + 
                (conversion_rate * 10 * 0.3) + 
                (revenue_per_customer * 0.3)
            ELSE 0 
        END as performance_score
    FROM rolling_metrics
)

SELECT * FROM growth_metrics 