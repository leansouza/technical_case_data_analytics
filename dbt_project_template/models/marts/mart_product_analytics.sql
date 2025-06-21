{{
  config(
    materialized='table',
    tags=['marts']
  )
}}

WITH product_analytics AS (
    SELECT
        pp.product_id,
        pp.product_name,
        pp.brand_id,
        pp.category_id,
        pp.price,
        pp.cost,
        pp.margin_percentage,
        pp.price_category,
        pp.is_available_for_sale,
        pp.orders_count,
        pp.total_quantity_sold,
        pp.total_revenue,
        pp.total_discounts,
        pp.net_revenue,
        pp.avg_quantity_per_order,
        pp.avg_unit_price,
        pp.unique_customers,
        pp.performance_score,
        pp.roi_percentage,
        pp.avg_discount_rate,
        pp.revenue_per_customer,
        pp.performance_segment,
        -- Informações da marca
        b.brand_name,
        b.standardized_brand_name,
        -- Informações da categoria
        pc.category_name,
        pc.standardized_category_name,
        pc.category_level,
        -- Métricas de performance
        CASE 
            WHEN pp.total_revenue > 0 THEN 
                (pp.total_revenue * 0.4) + 
                (pp.orders_count * 10 * 0.3) + 
                (COALESCE(pp.margin_percentage, 0) * 0.3)
            ELSE 0 
        END as enhanced_performance_score,
        -- Segmentação por receita
        CASE 
            WHEN pp.total_revenue >= 10000 THEN 'Top Revenue'
            WHEN pp.total_revenue >= 5000 THEN 'High Revenue'
            WHEN pp.total_revenue >= 2000 THEN 'Medium Revenue'
            WHEN pp.total_revenue >= 500 THEN 'Low Revenue'
            ELSE 'No Revenue'
        END as revenue_segment,
        -- Segmentação por margem
        CASE 
            WHEN pp.margin_percentage >= 50 THEN 'High Margin'
            WHEN pp.margin_percentage >= 30 THEN 'Medium Margin'
            WHEN pp.margin_percentage >= 15 THEN 'Low Margin'
            ELSE 'No Margin'
        END as margin_segment,
        -- Segmentação por popularidade
        CASE 
            WHEN pp.orders_count >= 20 THEN 'Very Popular'
            WHEN pp.orders_count >= 10 THEN 'Popular'
            WHEN pp.orders_count >= 5 THEN 'Moderate'
            WHEN pp.orders_count >= 1 THEN 'Low Popularity'
            ELSE 'Unpopular'
        END as popularity_segment
    FROM {{ ref('int_product_performance') }} pp
    LEFT JOIN {{ ref('stg_brands') }} b ON pp.brand_id = b.brand_id
    LEFT JOIN {{ ref('stg_product_categories') }} pc ON pp.category_id = pc.category_id
),

product_insights AS (
    SELECT
        *,
        -- Score de lucratividade
        CASE 
            WHEN margin_percentage > 0 AND total_revenue > 0 THEN 
                (margin_percentage * total_revenue) / 100
            ELSE 0 
        END as profitability_score,
        -- Eficiência de vendas
        CASE 
            WHEN price > 0 AND total_quantity_sold > 0 THEN 
                total_revenue / (price * total_quantity_sold)
            ELSE 0 
        END as sales_efficiency,
        -- Taxa de conversão de produto
        CASE 
            WHEN unique_customers > 0 THEN 
                orders_count / unique_customers
            ELSE 0 
        END as product_conversion_rate,
        -- Segmentação combinada
        CASE 
            WHEN revenue_segment = 'Top Revenue' AND margin_segment = 'High Margin' THEN 'Star Product'
            WHEN revenue_segment = 'High Revenue' AND margin_segment = 'High Margin' THEN 'Cash Cow'
            WHEN revenue_segment = 'Top Revenue' AND margin_segment IN ('Low Margin', 'No Margin') THEN 'Volume Product'
            WHEN revenue_segment IN ('Low Revenue', 'No Revenue') AND margin_segment = 'High Margin' THEN 'Niche Product'
            WHEN revenue_segment IN ('Low Revenue', 'No Revenue') AND margin_segment IN ('Low Margin', 'No Margin') THEN 'Question Mark'
            ELSE 'Regular Product'
        END as product_strategy_segment
    FROM product_analytics
)

SELECT * FROM product_insights 