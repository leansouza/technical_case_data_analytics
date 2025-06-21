{{
  config(
    materialized='table',
    tags=['marts']
  )
}}

WITH brand_performance AS (
    SELECT
        bm.brand_id,
        bm.brand_name,
        bm.standardized_brand_name,
        bm.is_active_brand,
        bm.total_products,
        bm.unique_customers,
        bm.total_orders,
        bm.total_revenue,
        bm.total_discounts,
        bm.total_shipping,
        bm.total_tax,
        bm.avg_order_value,
        bm.completed_orders,
        bm.cancelled_orders,
        bm.net_revenue,
        bm.conversion_rate,
        bm.cancellation_rate,
        bm.revenue_per_customer,
        bm.revenue_per_product,
        bm.discount_rate,
        bm.performance_score,
        bm.performance_segment,
        bm.size_segment,
        -- Informações da marca
        b.website,
        b.is_valid_website,
        -- Métricas de performance aprimoradas
        CASE 
            WHEN bm.total_revenue > 0 THEN 
                (bm.total_revenue * 0.4) + 
                (bm.unique_customers * 10 * 0.3) + 
                (bm.conversion_rate * 0.3)
            ELSE 0 
        END as enhanced_performance_score,
        -- Eficiência operacional
        CASE 
            WHEN bm.total_orders > 0 THEN 
                bm.completed_orders / bm.total_orders
            ELSE 0 
        END as operational_efficiency,
        -- Taxa de retenção estimada
        CASE 
            WHEN bm.unique_customers > 0 THEN 
                (bm.total_orders / bm.unique_customers) * 100
            ELSE 0 
        END as estimated_retention_rate,
        -- Margem operacional
        CASE 
            WHEN bm.total_revenue > 0 THEN 
                ((bm.net_revenue - bm.total_shipping - bm.total_tax) / bm.total_revenue) * 100
            ELSE 0 
        END as operating_margin
    FROM {{ ref('int_brand_metrics') }} bm
    LEFT JOIN {{ ref('stg_brands') }} b ON bm.brand_id = b.brand_id
),

brand_insights AS (
    SELECT
        *,
        -- Segmentação por receita
        CASE 
            WHEN total_revenue >= 50000 THEN 'Enterprise'
            WHEN total_revenue >= 20000 THEN 'Large'
            WHEN total_revenue >= 10000 THEN 'Medium'
            WHEN total_revenue >= 5000 THEN 'Small'
            ELSE 'Micro'
        END as revenue_segment,
        -- Segmentação por eficiência
        CASE 
            WHEN conversion_rate >= 90 THEN 'Excellent'
            WHEN conversion_rate >= 80 THEN 'Good'
            WHEN conversion_rate >= 70 THEN 'Average'
            WHEN conversion_rate >= 60 THEN 'Below Average'
            ELSE 'Poor'
        END as efficiency_segment,
        -- Segmentação por margem
        CASE 
            WHEN operating_margin >= 30 THEN 'High Margin'
            WHEN operating_margin >= 20 THEN 'Medium Margin'
            WHEN operating_margin >= 10 THEN 'Low Margin'
            ELSE 'Negative Margin'
        END as margin_segment,
        -- Score de saúde da marca
        CASE 
            WHEN conversion_rate >= 80 AND operating_margin >= 20 AND estimated_retention_rate >= 150 THEN 'Excellent'
            WHEN conversion_rate >= 70 AND operating_margin >= 15 AND estimated_retention_rate >= 120 THEN 'Good'
            WHEN conversion_rate >= 60 AND operating_margin >= 10 AND estimated_retention_rate >= 100 THEN 'Average'
            WHEN conversion_rate >= 50 AND operating_margin >= 5 AND estimated_retention_rate >= 80 THEN 'Below Average'
            ELSE 'Poor'
        END as brand_health_score,
        -- Estratégia recomendada
        CASE 
            WHEN revenue_segment = 'Enterprise' AND efficiency_segment = 'Excellent' THEN 'Maintain Leadership'
            WHEN revenue_segment = 'Large' AND efficiency_segment = 'Good' THEN 'Scale Operations'
            WHEN revenue_segment = 'Medium' AND efficiency_segment = 'Average' THEN 'Optimize Performance'
            WHEN revenue_segment = 'Small' AND efficiency_segment = 'Below Average' THEN 'Improve Efficiency'
            WHEN revenue_segment = 'Micro' AND efficiency_segment = 'Poor' THEN 'Rebuild Strategy'
            ELSE 'Monitor and Adjust'
        END as recommended_strategy
    FROM brand_performance
)

SELECT * FROM brand_insights 