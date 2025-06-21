# Decisões de Design - E-commerce Analytics

## 🎯 Minha Abordagem como Engenheiro de Dados Senior

Como engenheiro de dados com experiência em projetos de grande escala, decidi implementar esta solução seguindo as melhores práticas e considerando os desafios específicos identificados no projeto original.

## 🏗️ Por que Escolhi a Arquitetura em Camadas

### 1. **Separação de Responsabilidades**

Decidi implementar uma arquitetura em 4 camadas (Raw → Staging → Intermediate → Marts) porque:

- **Problema identificado**: Os modelos existentes misturavam diferentes responsabilidades, causando confusão e dificuldade de manutenção
- **Solução**: Cada camada tem um propósito específico e bem definido
- **Benefício**: Facilita debugging, manutenção e escalabilidade

### 2. **Camada Staging - Por que Implementei Assim**

**Decisão**: Criar modelos de staging que fazem limpeza e validação básica

**Justificativa**:
- Os dados brutos tinham inconsistências (emails não padronizados, valores negativos, strings com espaços)
- Precisava garantir qualidade antes de processar
- Implementei validações de negócio (emails válidos, valores positivos, datas válidas)
- Adicionei flags de validação para facilitar troubleshooting

**Exemplo prático**: No `stg_customers`, implementei:
```sql
-- Validação de email com regex
CASE 
    WHEN email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' 
    THEN true 
    ELSE false 
END as is_valid_email
```

### 3. **Camada Intermediate - A Lógica de Negócio Centralizada**

**Decisão**: Criar modelos intermediários para agregações e cálculos complexos

**Por que fiz isso**:
- Os modelos originais repetiam cálculos em diferentes lugares
- Precisava de reutilização de lógica comum
- Queria otimizar performance com agregações pré-calculadas

**Exemplo**: No `int_orders_customers`, centralizei:
- Cálculo de recência (days_since_last_order)
- Segmentação por valor (High/Medium/Low Value)
- Taxas de conversão e cancelamento
- Métricas de cliente reutilizáveis

### 4. **Camada Marts - Modelos Finais Otimizados**

**Decisão**: Criar marts específicos para diferentes análises de negócio

**Justificativa**:
- Os modelos originais misturavam diferentes níveis de granularidade
- Precisava de modelos prontos para consumo por analistas
- Implementei segmentações avançadas (RFM, estratégias de produto)

**Inovação**: Criei segmentações que não existiam no modelo original:
- **RFM Analysis**: Champions, Loyal Customers, At Risk, etc.
- **Product Strategy**: Star, Cash Cow, Volume, Niche Products
- **Brand Health**: Scores de saúde e estratégias recomendadas

## 🔧 Decisões Técnicas Específicas

### 1. **Materialização dos Modelos**

**Decisão**: 
- Staging: Views (atualização em tempo real)
- Intermediate: Tables (performance otimizada)
- Marts: Tables (consulta otimizada)

**Por que**: Views para staging permitem ver mudanças imediatas nos dados brutos, enquanto tables para intermediate/marts otimizam performance para consultas complexas.

### 2. **Convenções de Nomenclatura**

**Decisão**: Usar prefixos claros (stg_, int_, mart_) e nomes descritivos

**Justificativa**: Os modelos originais tinham nomes inconsistentes (brand_performance vs customer_orders). Padronizei para facilitar navegação e manutenção.

### 3. **Testes de Qualidade**

**Decisão**: Implementar testes customizados além dos testes padrão do dbt

**Por que**: Identifiquei problemas específicos no modelo original:
- Totais de pedidos não batiam com itens
- Emails em formato inválido
- Valores monetários negativos

**Implementei**:
```sql
-- Teste de integridade de pedidos
SELECT order_id, order_total, calculated_total
FROM order_totals
WHERE ABS(order_total - calculated_total) > 0.01
```

## 📊 Métricas e KPIs - Por que Escolhi Essas

### 1. **Customer Analytics - RFM Analysis**

**Decisão**: Implementar segmentação RFM completa

**Justificativa**: O modelo original não tinha segmentação de clientes. Implementei porque:
- Permite estratégias de marketing direcionadas
- Identifica clientes em risco de churn (Churn é uma métrica que indica o quanto sua empresa perdeu de receita ou clientes)
- Facilita campanhas de retenção

### 2. **Product Performance - Segmentação Estratégica**

**Decisão**: Criar segmentação baseada em receita e margem

**Por que**: Os produtos precisam de estratégias diferentes:
- **Star Products**: Alta receita + alta margem → Investir
- **Cash Cows**: Alta receita + margem moderada → Manter
- **Question Marks**: Baixa receita + baixa margem → Reavaliar

### 3. **Sales Performance - Métricas Temporais**

**Decisão**: Implementar médias móveis e crescimento

**Justificativa**: Para análise de tendências e performance temporal, essencial para:
- Identificar padrões sazonais
- Medir crescimento
- Detectar anomalias

## 🚀 Otimizações de Performance

### 1. **Joins Otimizados**

**Problema original**: Múltiplos joins ineficientes
```sql
-- ANTES (modelo original)
FROM brands b
LEFT JOIN products p ON b.brand_id = p.brand_id
LEFT JOIN order_items oi ON p.product_id = oi.product_id
LEFT JOIN orders o ON oi.order_id = o.order_id
LEFT JOIN customers c ON o.customer_id = c.customer_id
```

**Solução**: Separei em camadas e otimizei joins:
```sql
-- DEPOIS (camada intermediate)
FROM {{ ref('stg_orders') }} o
LEFT JOIN {{ ref('stg_customers') }} c ON o.customer_id = c.customer_id
```

### 2. **Agregações Pré-calculadas**

**Decisão**: Calcular métricas complexas nas camadas intermediate

**Benefício**: Evita recálculos em cada consulta, melhorando performance significativamente.

## 🧪 Qualidade de Dados - Minha Abordagem

### 1. **Validações em Múltiplas Camadas**

**Decisão**: Implementar validações em cada camada

**Por que**: Garantir qualidade desde o início do pipeline:
- **Staging**: Validações básicas (formato, tipos)
- **Intermediate**: Validações de negócio (lógica)
- **Marts**: Validações finais (integridade)

### 2. **Testes Customizados**

**Decisão**: Criar testes específicos para regras de negócio

**Exemplo**: Teste de integridade de pedidos
```sql
-- Valida se totais de pedidos correspondem aos itens
WHERE ABS(order_total - calculated_total) > 0.01
```

## 📈 Escalabilidade - Como Preparei para o Futuro

### 1. **Particionamento**

**Decisão**: Configurar para particionamento por data

**Justificativa**: Para volumes grandes de dados, particionamento é essencial para performance.

### 2. **Índices Estratégicos**

**Decisão**: Definir índices nas configurações YAML

**Por que**: Otimizar consultas frequentes por data, cliente e marca.

### 3. **Macros Reutilizáveis**

**Decisão**: Preparar estrutura para macros

**Benefício**: Permite reutilização de lógica comum e facilita manutenção.

## 🎯 Resolução dos Problemas Identificados

### 1. **Problema**: Joins ineficientes
**Solução**: Separação em camadas + joins otimizados

### 2. **Problema**: Cálculos redundantes
**Solução**: Centralização em camadas intermediate

### 3. **Problema**: Falta de separação em camadas
**Solução**: Arquitetura em 4 camadas bem definidas

### 4. **Problema**: Inconsistência de nomenclatura
**Solução**: Convenções padronizadas (stg_, int_, mart_)

### 5. **Problema**: Ausência de testes
**Solução**: Testes automatizados em todas as camadas

## 🔮 Considerações para o Futuro

### 1. **Machine Learning Integration**
Preparei a estrutura para facilitar integração com ML:
- Features engineering nas camadas intermediate
- Métricas normalizadas nos marts
- Dados limpos e consistentes

### 2. **Real-time Processing**
A arquitetura permite evolução para real-time:
- Staging como views para mudanças imediatas
- Estrutura modular para streaming

### 3. **Multi-cloud Support**
Configurei para ser agnóstico ao warehouse:
- SQL padrão
- Configurações flexíveis
- Sem dependências específicas

## 📋 Conclusão

Esta implementação representa uma evolução significativa do modelo original, resolvendo todos os problemas identificados e preparando o sistema para escalar com o crescimento do negócio. E as decisões tomadas seguem as melhores práticas e consideram tanto as necessidades atuais quanto o futuro da plataforma.

A arquitetura implementada não apenas resolve os problemas existentes, mas também introduz capacidades analíticas avançadas que não existiam no modelo original, como segmentação RFM, análise estratégica de produtos e insights de marca com recomendações automatizadas.
