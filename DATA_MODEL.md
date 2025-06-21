# Modelo de Dados - E-commerce Analytics

## 📊 Visão Geral do Modelo

Este documento descreve o modelo de dados implementado para análise de e-commerce, seguindo as melhores práticas de modelagem dimensional e arquitetura em camadas.

## 🏗️ Arquitetura do Modelo

### Camadas de Dados

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              RAW DATA LAYER                                 │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐          │
│  │  customers  │ │   orders    │ │  products   │ │ order_items │          │
│  │    .csv     │ │    .csv     │ │    .csv     │ │    .csv     │          │
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘          │
│  ┌─────────────┐ ┌─────────────┐                                          │
│  │ stg_brands  │ │stg_product_ │                                          │
│  │    .csv     │ │ categories  │                                          │
│  └─────────────┘ └─────────────┘                                          │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                            STAGING LAYER                                    │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐          │
│  │stg_customers│ │ stg_orders  │ │stg_products │ │stg_order_   │          │
│  │             │ │             │ │             │ │   items     │          │
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘          │
│  ┌─────────────┐ ┌─────────────┐                                          │
│  │ stg_brands  │ │stg_product_ │                                          │
│  │             │ │ categories  │                                          │
│  └─────────────┘ └─────────────┘                                          │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         INTERMEDIATE LAYER                                 │
│  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐              │
│  │int_orders_      │ │int_product_     │ │int_brand_       │              │
│  │  customers      │ │  performance    │ │  metrics        │              │
│  └─────────────────┘ └─────────────────┘ └─────────────────┘              │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                              MARTS LAYER                                   │
│  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐              │
│  │mart_customer_   │ │mart_sales_      │ │mart_product_    │              │
│  │  analytics      │ │  performance    │ │  analytics      │              │
│  └─────────────────┘ └─────────────────┘ └─────────────────┘              │
│  ┌─────────────────┐                                                      │
│  │mart_brand_      │                                                      │
│  │  performance    │                                                      │
│  └─────────────────┘                                                      │
└─────────────────────────────────────────────────────────────────────────────┘
```

## 📋 Detalhamento das Tabelas

### 1. Staging Layer

#### stg_customers
**Propósito**: Limpeza e padronização de dados de clientes

| Campo | Tipo | Descrição | Validações |
|-------|------|-----------|------------|
| customer_id | INTEGER | ID único do cliente | Unique, Not Null |
| first_name | VARCHAR | Nome do cliente | Trim, Not Null |
| last_name | VARCHAR | Sobrenome do cliente | Trim, Not Null |
| email | VARCHAR | Email do cliente | Lower, Trim, Regex |
| full_name | VARCHAR | Nome completo | Concatenação |
| city | VARCHAR | Cidade | Trim |
| state | VARCHAR | Estado | Trim |
| country | VARCHAR | País | Padronização |
| brand_id | INTEGER | ID da marca | Not Null |
| is_valid_email | BOOLEAN | Validação de email | Regex |
| created_at | TIMESTAMP | Data de criação | |
| updated_at | TIMESTAMP | Data de atualização | |

#### stg_orders
**Propósito**: Normalização e validação de pedidos

| Campo | Tipo | Descrição | Validações |
|-------|------|-----------|------------|
| order_id | INTEGER | ID único do pedido | Unique, Not Null |
| customer_id | INTEGER | ID do cliente | Not Null |
| order_date | DATE | Data do pedido | Not Null |
| order_status | VARCHAR | Status do pedido | Enum |
| payment_method | VARCHAR | Método de pagamento | |
| total_amount | DECIMAL | Valor total | >= 0 |
| shipping_amount | DECIMAL | Valor do frete | >= 0 |
| tax_amount | DECIMAL | Valor dos impostos | >= 0 |
| discount_amount | DECIMAL | Valor do desconto | >= 0 |
| net_amount | DECIMAL | Valor líquido | Calculado |
| currency | VARCHAR | Moeda | |
| brand_id | INTEGER | ID da marca | Not Null |
| is_valid_amount | BOOLEAN | Validação de valor | >= 0 |
| is_valid_date | BOOLEAN | Validação de data | <= Current |
| has_discount | BOOLEAN | Flag de desconto | > 0 |

#### stg_products
**Propósito**: Padronização de produtos com métricas

| Campo | Tipo | Descrição | Validações |
|-------|------|-----------|------------|
| product_id | INTEGER | ID único do produto | Unique, Not Null |
| product_name | VARCHAR | Nome do produto | Trim, Not Null |
| description | VARCHAR | Descrição | Trim |
| price | DECIMAL | Preço | > 0 |
| cost | DECIMAL | Custo | >= 0 |
| brand_id | INTEGER | ID da marca | Not Null |
| category_id | INTEGER | ID da categoria | Not Null |
| margin_percentage | DECIMAL | Margem calculada | (price-cost)/price |
| price_category | VARCHAR | Categoria de preço | Case |
| is_available_for_sale | BOOLEAN | Disponível para venda | Logic |
| is_active | BOOLEAN | Produto ativo | |

### 2. Intermediate Layer

#### int_orders_customers
**Propósito**: Agregações de pedidos por cliente

| Campo | Tipo | Descrição | Cálculo |
|-------|------|-----------|---------|
| customer_id | INTEGER | ID do cliente | |
| total_orders | INTEGER | Total de pedidos | COUNT(DISTINCT) |
| total_spent | DECIMAL | Total gasto | SUM(total_amount) |
| avg_order_value | DECIMAL | Valor médio | AVG(total_amount) |
| first_order_date | DATE | Primeiro pedido | MIN(order_date) |
| last_order_date | DATE | Último pedido | MAX(order_date) |
| days_since_last_order | INTEGER | Dias desde último | DATEDIFF |
| value_segment | VARCHAR | Segmento por valor | Case |
| conversion_rate | DECIMAL | Taxa de conversão | completed/total |
| cancellation_rate | DECIMAL | Taxa de cancelamento | cancelled/total |

#### int_product_performance
**Propósito**: Métricas de performance por produto

| Campo | Tipo | Descrição | Cálculo |
|-------|------|-----------|---------|
| product_id | INTEGER | ID do produto | |
| orders_count | INTEGER | Número de pedidos | COUNT(DISTINCT) |
| total_quantity_sold | INTEGER | Quantidade vendida | SUM(quantity) |
| total_revenue | DECIMAL | Receita total | SUM(total_price) |
| net_revenue | DECIMAL | Receita líquida | SUM(net_price) |
| performance_score | DECIMAL | Score de performance | Weighted |
| roi_percentage | DECIMAL | ROI | (revenue-cost)/cost |
| avg_discount_rate | DECIMAL | Taxa de desconto | AVG(discount) |
| revenue_per_customer | DECIMAL | Receita por cliente | revenue/customers |

### 3. Marts Layer

#### mart_customer_analytics
**Propósito**: Análise completa de clientes com RFM

| Campo | Tipo | Descrição | Segmentação |
|-------|------|-----------|-------------|
| customer_id | INTEGER | ID do cliente | |
| customer_segment | VARCHAR | Segmento RFM | Champions, Loyal, At Risk, etc. |
| rfm_score | DECIMAL | Score RFM | (R+F+M)/3 |
| recency_score | INTEGER | Score de recência | 1-5 |
| frequency_score | INTEGER | Score de frequência | 1-5 |
| monetary_score | INTEGER | Score monetário | 1-5 |
| estimated_clv | DECIMAL | CLV estimado | total_spent * conversion |
| customer_value_tier | VARCHAR | Nível de valor | VIP, Premium, Regular, etc. |
| activity_status | VARCHAR | Status de atividade | Active, Recent, At Risk, etc. |

#### mart_sales_performance
**Propósito**: Performance de vendas por data e marca

| Campo | Tipo | Descrição | Cálculo |
|-------|------|-----------|---------|
| sale_date | DATE | Data da venda | |
| brand_id | INTEGER | ID da marca | |
| orders_count | INTEGER | Número de pedidos | COUNT(DISTINCT) |
| total_revenue | DECIMAL | Receita total | SUM(total_amount) |
| net_revenue | DECIMAL | Receita líquida | total - discounts |
| conversion_rate | DECIMAL | Taxa de conversão | completed/total |
| revenue_7d_avg | DECIMAL | Média 7 dias | Rolling Average |
| revenue_30d_avg | DECIMAL | Média 30 dias | Rolling Average |
| daily_revenue_growth | DECIMAL | Crescimento diário | (today-yesterday)/yesterday |
| performance_score | DECIMAL | Score de performance | Weighted |

#### mart_product_analytics
**Propósito**: Análise completa de produtos

| Campo | Tipo | Descrição | Segmentação |
|-------|------|-----------|-------------|
| product_id | INTEGER | ID do produto | |
| performance_segment | VARCHAR | Segmento de performance | Top, High, Medium, Low |
| revenue_segment | VARCHAR | Segmento por receita | Top, High, Medium, Low |
| margin_segment | VARCHAR | Segmento por margem | High, Medium, Low |
| popularity_segment | VARCHAR | Segmento por popularidade | Very Popular, Popular, etc. |
| product_strategy_segment | VARCHAR | Segmento estratégico | Star, Cash Cow, Volume, etc. |
| profitability_score | DECIMAL | Score de lucratividade | margin * revenue |
| sales_efficiency | DECIMAL | Eficiência de vendas | revenue/(price*quantity) |

#### mart_brand_performance
**Propósito**: Performance por marca com insights

| Campo | Tipo | Descrição | Segmentação |
|-------|------|-----------|-------------|
| brand_id | INTEGER | ID da marca | |
| performance_segment | VARCHAR | Segmento de performance | Top, High, Medium, Low |
| size_segment | VARCHAR | Segmento por tamanho | Large, Medium, Small, Micro |
| revenue_segment | VARCHAR | Segmento por receita | Enterprise, Large, Medium, etc. |
| efficiency_segment | VARCHAR | Segmento por eficiência | Excellent, Good, Average, etc. |
| brand_health_score | VARCHAR | Score de saúde | Excellent, Good, Average, etc. |
| recommended_strategy | VARCHAR | Estratégia recomendada | Maintain, Scale, Optimize, etc. |
| operating_margin | DECIMAL | Margem operacional | (net-shipping-tax)/revenue |

## 🔗 Relacionamentos

### Chaves Primárias
- `customers.customer_id`
- `orders.order_id`
- `products.product_id`
- `order_items.order_item_id`
- `brands.brand_id`
- `product_categories.category_id`

### Chaves Estrangeiras
- `orders.customer_id` → `customers.customer_id`
- `orders.brand_id` → `brands.brand_id`
- `order_items.order_id` → `orders.order_id`
- `order_items.product_id` → `products.product_id`
- `products.brand_id` → `brands.brand_id`
- `products.category_id` → `product_categories.category_id`
- `customers.brand_id` → `brands.brand_id`

## 📊 Métricas Principais

### Customer Metrics
- **Customer Lifetime Value (CLV)**: Valor total esperado de um cliente
- **Recency**: Dias desde a última compra
- **Frequency**: Número total de pedidos
- **Monetary**: Valor total gasto
- **Conversion Rate**: Taxa de conversão de pedidos

### Sales Metrics
- **Total Revenue**: Receita total
- **Net Revenue**: Receita líquida (total - descontos)
- **Average Order Value (AOV)**: Valor médio por pedido
- **Conversion Rate**: Taxa de conversão
- **Growth Rate**: Taxa de crescimento

### Product Metrics
- **Performance Score**: Score combinado de performance
- **ROI**: Return on Investment
- **Margin Percentage**: Percentual de margem
- **Sales Efficiency**: Eficiência de vendas
- **Popularity Score**: Score de popularidade

### Brand Metrics
- **Performance Score**: Score de performance da marca
- **Operational Efficiency**: Eficiência operacional
- **Customer Retention**: Taxa de retenção
- **Operating Margin**: Margem operacional
- **Health Score**: Score de saúde da marca

## 🎯 Segmentações

### Customer Segmentation (RFM)
1. **Champions**: Clientes de alto valor e alta frequência
2. **Loyal Customers**: Clientes fiéis com boa frequência
3. **At Risk**: Clientes que podem estar perdendo interesse
4. **Cant Lose**: Clientes de alto valor que precisam de atenção
5. **About to Sleep**: Clientes com baixa recência
6. **Need Attention**: Clientes que precisam de reativação
7. **Lost**: Clientes inativos

### Product Strategy Segmentation
1. **Star Product**: Alta receita e alta margem
2. **Cash Cow**: Alta receita e margem moderada
3. **Volume Product**: Alta receita e baixa margem
4. **Niche Product**: Baixa receita e alta margem
5. **Question Mark**: Baixa receita e baixa margem
6. **Regular Product**: Performance média

### Brand Strategy Segmentation
1. **Maintain Leadership**: Marca líder com excelente performance
2. **Scale Operations**: Marca grande com boa performance
3. **Optimize Performance**: Marca média com performance média
4. **Improve Efficiency**: Marca pequena com baixa eficiência
5. **Rebuild Strategy**: Marca micro com performance ruim
6. **Monitor and Adjust**: Outras combinações

## 🔧 Configurações de Performance

### Materialização
- **Staging**: Views (atualização em tempo real)
- **Intermediate**: Tables (performance otimizada)
- **Marts**: Tables (consulta otimizada)

### Índices Recomendados
```sql
-- Orders
CREATE INDEX idx_orders_date ON stg_orders(order_date);
CREATE INDEX idx_orders_customer ON stg_orders(customer_id, brand_id);

-- Products
CREATE INDEX idx_products_brand ON stg_products(brand_id, category_id);

-- Sales Performance
CREATE INDEX idx_sales_date_brand ON mart_sales_performance(sale_date, brand_id);
```

### Particionamento
- **Orders**: Por `order_date` (mensal)
- **Sales Performance**: Por `sale_date` (diário)
- **Customer Analytics**: Por `brand_id`

## 🧪 Estratégia de Testes

### Testes por Camada

#### Staging Layer
- **Uniqueness**: Chaves primárias únicas
- **Not null**: Campos obrigatórios
- **Data types**: Validação de tipos
- **Range checks**: Valores dentro de limites esperados

#### Intermediate Layer
- **Business logic**: Validação de cálculos
- **Referential integrity**: Relacionamentos válidos
- **Data completeness**: Dados completos

#### Marts Layer
- **End-to-end**: Validação completa do pipeline
- **Performance**: Tempo de execução
- **Data quality**: Qualidade final dos dados

### Testes Customizados
```sql
-- Exemplo: Validação de totais de pedidos
SELECT 
    order_id,
    total_amount,
    calculated_total,
    ABS(total_amount - calculated_total) as difference
FROM {{ ref('mart_sales_performance') }}
WHERE ABS(total_amount - calculated_total) > 0.01
```