{{
  config(
    materialized='table',
    tags=['marts']
  )
}}

WITH customer_analytics AS (
    SELECT
        customer_id,
        first_name,
        last_name,
        email,
        full_name,
        city,
        state,
        country,
        brand_id,
        is_valid_email,
        total_orders,
        total_spent,
        avg_order_value,
        first_order_date,
        last_order_date,
        total_discounts,
        completed_orders,
        cancelled_orders,
        processing_orders,
        shipped_orders,
        total_shipping,
        total_tax,
        days_since_last_order,
        value_segment,
        conversion_rate,
        cancellation_rate,
        avg_discount_per_order,
        -- Customer Lifetime Value (CLV) estimado
        total_spent * (conversion_rate / 100) as estimated_clv,
        -- Recency Score (1-5)
        CASE 
            WHEN days_since_last_order <= 30 THEN 5
            WHEN days_since_last_order <= 90 THEN 4
            WHEN days_since_last_order <= 180 THEN 3
            WHEN days_since_last_order <= 365 THEN 2
            ELSE 1
        END as recency_score,
        -- Frequency Score (1-5)
        CASE 
            WHEN total_orders >= 10 THEN 5
            WHEN total_orders >= 5 THEN 4
            WHEN total_orders >= 3 THEN 3
            WHEN total_orders >= 2 THEN 2
            ELSE 1
        END as frequency_score,
        -- Monetary Score (1-5)
        CASE 
            WHEN total_spent >= 1000 THEN 5
            WHEN total_spent >= 500 THEN 4
            WHEN total_spent >= 200 THEN 3
            WHEN total_spent >= 100 THEN 2
            ELSE 1
        END as monetary_score
    FROM {{ ref('int_orders_customers') }}
),

rfm_analysis AS (
    SELECT
        *,
        -- Score RFM combinado
        (recency_score + frequency_score + monetary_score) / 3 as rfm_score,
        -- Segmentação RFM
        CASE 
            WHEN (recency_score + frequency_score + monetary_score) / 3 >= 4.5 THEN 'Champions'
            WHEN (recency_score + frequency_score + monetary_score) / 3 >= 4.0 THEN 'Loyal Customers'
            WHEN (recency_score + frequency_score + monetary_score) / 3 >= 3.5 THEN 'At Risk'
            WHEN (recency_score + frequency_score + monetary_score) / 3 >= 3.0 THEN 'Cant Lose'
            WHEN (recency_score + frequency_score + monetary_score) / 3 >= 2.5 THEN 'About to Sleep'
            WHEN (recency_score + frequency_score + monetary_score) / 3 >= 2.0 THEN 'Need Attention'
            ELSE 'Lost'
        END as customer_segment,
        -- Valor do cliente
        CASE 
            WHEN total_spent >= 1000 AND conversion_rate >= 80 THEN 'VIP'
            WHEN total_spent >= 500 AND conversion_rate >= 70 THEN 'Premium'
            WHEN total_spent >= 200 AND conversion_rate >= 60 THEN 'Regular'
            WHEN total_spent >= 100 THEN 'Occasional'
            ELSE 'New'
        END as customer_value_tier,
        -- Status de atividade
        CASE 
            WHEN days_since_last_order <= 30 THEN 'Active'
            WHEN days_since_last_order <= 90 THEN 'Recent'
            WHEN days_since_last_order <= 180 THEN 'At Risk'
            WHEN days_since_last_order <= 365 THEN 'Inactive'
            ELSE 'Lost'
        END as activity_status
    FROM customer_analytics
)

SELECT * FROM rfm_analysis 