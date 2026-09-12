-- Recência (R): A diferença em dias entre a data máxima do banco de dados (ou a data atual) e a última compra do cliente.
-- Frequência (F): O total de pedidos únicos feitos pelo cliente.
-- Valor Monetário (M): A soma do faturamento total gerado por esse cliente.
SELECT ocd.customer_unique_id AS customer, CAST(julianday('2018-10-17') - julianday(MAX(ood.order_purchase_timestamp)) AS INTEGER) AS ultima_compra, COUNT(DISTINCT ood.order_id) AS total_pedido, SUM(ooid.price) AS faturamento_cliente
FROM olist_customers_dataset ocd
JOIN olist_orders_dataset ood ON ood.customer_id = ocd.customer_id 
JOIN olist_order_items_dataset ooid ON ooid.order_id = ood.order_id
GROUP BY ocd.customer_unique_id;

/* Segmentação RFM (Recência, Frequência e Valor Monetário):
Recência: Há quantos dias o cliente fez a última compra?
Frequência: Quantas compras ele realizou no total?
Valor: Quanto ele já gastou na plataforma no total?
Objetivo: Classificar os clientes em grupos como VIPs, Clientes Promissores, Em Risco e Inativos. */
WITH rfm_base AS (
    -- Calcula as métricas brutas de Recência, Frequência e Valor Monetário
    SELECT 
        ocd.customer_unique_id AS customer,
        CAST(julianday('2018-10-17') - julianday(MAX(ood.order_purchase_timestamp)) AS INTEGER) AS recencia_dias,
        COUNT(DISTINCT ood.order_id) AS frequencia,
        SUM(ooid.price) AS valor_monetario
    FROM olist_customers_dataset ocd
    JOIN olist_orders_dataset ood ON ood.customer_id = ocd.customer_id 
    JOIN olist_order_items_dataset ooid ON ooid.order_id = ood.order_id
    GROUP BY ocd.customer_unique_id
),
rfm_scores AS (
    -- Atribui pontuações de 1 a 4 (Quartis) para R, F e M
    SELECT 
        customer,
        recencia_dias,
        frequencia,
        valor_monetario,
        NTILE(4) OVER (ORDER BY recencia_dias DESC) AS score_r, -- Menos dias recém-comprados = Score mais alto (4)
        NTILE(4) OVER (ORDER BY frequencia ASC) AS score_f,     -- Mais compras = Score mais alto (4)
        NTILE(4) OVER (ORDER BY valor_monetario ASC) AS score_m -- Maior valor gasto = Score mais alto (4)
    FROM rfm_base
)
-- Agrupa e classifica os clientes em categorias de negócio
SELECT 
    customer,
    recencia_dias,
    frequencia,
    ROUND(valor_monetario, 2) AS valor_monetario,
    score_r,
    score_f,
    score_m,
    (score_r || score_f || score_m) AS rfm_cell,
    CASE 
        WHEN score_r = 4 AND score_f >= 3 AND score_m >= 3 THEN 'VIP / Campeões'
        WHEN score_r >= 3 AND score_f >= 1 AND score_m >= 3 THEN 'Clientes Leais / Alto Valor'
        WHEN score_r >= 3 AND score_f >= 1 AND score_m < 3 THEN 'Novos / Promissores'
        WHEN score_r <= 2 AND score_m >= 3 THEN 'Em Risco / Alto Valor Sumindo'
        WHEN score_r <= 2 AND score_m < 3 THEN 'Inativos / Churn'
        ELSE 'Em Atenção'
    END AS segmento_cliente
FROM rfm_scores
ORDER BY valor_monetario DESC;

-- Análise de Coorte (Cohort Analysis): Qual é a taxa de retenção dos clientes agrupados pelo mês da primeira compra ao longo dos meses subsequentes?
WITH primeira_compra AS (
    -- Identifica o mes da primeira compra do cliente (Mes da Coorte)
    SELECT 
        ocd.customer_unique_id,
        MIN(strftime('%Y-%m-01', ood.order_purchase_timestamp)) AS mes_coorte
    FROM olist_customers_dataset ocd
    JOIN olist_orders_dataset ood ON ood.customer_id = ocd.customer_id
    WHERE ood.order_status = 'delivered'
    GROUP BY ocd.customer_unique_id
),
compras_clientes AS (
    -- Mapeia todas as compras de cada cliente e calcula a diferenca em meses
    SELECT 
        pc.customer_unique_id,
        pc.mes_coorte,
        strftime('%Y-%m-01', ood.order_purchase_timestamp) AS mes_pedido,
        -- Calcula a diferenca exata em meses entre a compra e a coorte
        (CAST(strftime('%Y', ood.order_purchase_timestamp) AS INTEGER) - CAST(strftime('%Y', pc.mes_coorte) AS INTEGER)) * 12 +
        (CAST(strftime('%m', ood.order_purchase_timestamp) AS INTEGER) - CAST(strftime('%m', pc.mes_coorte) AS INTEGER)) AS mes_atividade
    FROM primeira_compra pc
    JOIN olist_customers_dataset ocd ON ocd.customer_unique_id = pc.customer_unique_id
    JOIN olist_orders_dataset ood ON ood.customer_id = ocd.customer_id
    WHERE ood.order_status = 'delivered'
)
-- Agrupa por Coorte e Mes de Atividade para contar os clientes ativos
SELECT 
    mes_coorte,
    mes_atividade,
    COUNT(DISTINCT customer_unique_id) AS total_clientes
FROM compras_clientes
GROUP BY mes_coorte, mes_atividade
ORDER BY mes_coorte ASC, mes_atividade ASC;
