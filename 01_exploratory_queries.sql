-- Faturamento total
SELECT SUM(ooid.price) AS total_revenue
FROM olist_order_items_dataset ooid 
JOIN olist_orders_dataset ood ON ooid.order_id = ood.order_id;

-- Faturamento mês a mês
SELECT 
	strftime('%Y-%m', ood.order_approved_at) AS year_month,
	SUM(ooid.price) AS total_revenue
FROM olist_order_items_dataset ooid 
JOIN olist_orders_dataset ood ON ooid.order_id = ood.order_id
WHERE ood.order_approved_at IS NOT NULL
GROUP BY year_month
ORDER BY year_month ASC;

-- Quantos pedidos foram gerados no total:
SELECT COUNT(order_id) AS total_orders FROM olist_orders_dataset ood;

-- Ticket médio por cliente
SELECT SUM(ooid.price) / COUNT(DISTINCT ood.order_id) AS avg_ticket
FROM olist_order_items_dataset ooid 
JOIN olist_orders_dataset ood ON ooid.order_id = ood.order_id;

-- Qual a média de itens comprados por transação:
SELECT ROUND(CAST(COUNT(order_item_id) AS FLOAT) / COUNT(DISTINCT order_id), 2) AS avg_items_per_order
FROM olist_order_items_dataset ooid;

-- Quais estados ou cidades concentram o maior número de vendas e o maior faturamento:
SELECT ocd.customer_state AS estado, ocd.customer_city AS cidade, COUNT(DISTINCT ood.order_id) AS total_pedidos, 
	ROUND(SUM(ooid.price), 2) AS total_faturamento,
	ROUND(SUM(ooid.price) / COUNT(DISTINCT ood.order_id), 2) AS ticket_medio
FROM olist_orders_dataset ood 
JOIN olist_customers_dataset ocd ON ood.customer_id = ocd.customer_id 
JOIN olist_order_items_dataset ooid ON ood.order_id = ooid.order_id 
GROUP BY estado, cidade
ORDER BY total_faturamento DESC
LIMIT 5;

-- Qual a porcentagem do faturamento total que vem dos 20% principais clientes:
WITH faturamento_por_cliente AS (
    SELECT ocd.customer_unique_id, SUM(ooid.price) AS faturamento_cliente
    FROM olist_orders_dataset ood
    JOIN olist_customers_dataset ocd ON ocd.customer_id = ood.customer_id 
    JOIN olist_order_items_dataset ooid ON ooid.order_id = ood.order_id 
    GROUP BY ocd.customer_unique_id
),
clientes_com_grupo AS (
    SELECT customer_unique_id, faturamento_cliente, NTILE(5) OVER (ORDER BY faturamento_cliente DESC) AS grupo_percentil
    FROM faturamento_por_cliente
)
SELECT ROUND(SUM(CASE WHEN grupo_percentil = 1 THEN faturamento_cliente ELSE 0 END), 2) AS faturamento_top_20, ROUND(SUM(faturamento_cliente), 2) AS faturamento_total, 
	ROUND((SUM(CASE WHEN grupo_percentil = 1 THEN faturamento_cliente ELSE 0 END) * 100.0) / SUM(faturamento_cliente), 2) AS pct_faturamento_top_20
FROM clientes_com_grupo;

-- Quantos clientes compraram apenas uma única vez versus clientes que realizaram 2 ou mais compras?
WITH pedidos_por_cliente AS (
    SELECT ocd.customer_unique_id, COUNT(DISTINCT ooid.order_id) AS qtd_pedidos
    FROM olist_order_items_dataset ooid 
    JOIN olist_orders_dataset ood ON ood.order_id = ooid.order_id 
    JOIN olist_customers_dataset ocd ON ocd.customer_id = ood.customer_id
    GROUP BY ocd.customer_unique_id
)
SELECT qtd_pedidos, COUNT(DISTINCT customer_unique_id) AS total_de_clientes
FROM pedidos_por_cliente
GROUP BY qtd_pedidos
ORDER BY qtd_pedidos ASC;




	
	




