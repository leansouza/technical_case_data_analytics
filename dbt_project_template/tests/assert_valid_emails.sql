-- Teste para validar formato de emails
SELECT 
    customer_id,
    email
FROM {{ ref('stg_customers') }}
WHERE email !~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' 