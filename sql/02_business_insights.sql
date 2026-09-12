-- Quais são as 5 principais categorias de produtos em receita total e em volume total de vendas?
SELECT opd.product_category_name AS categoria, SUM(ooid.price) AS receita_total 
FROM olist_products_dataset opd
JOIN olist_order_items_dataset ooid ON ooid.product_id = opd.product_id
GROUP BY categoria
ORDER BY receita_total DESC
LIMIT 5;

SELECT opd.product_category_name AS categoria, COUNT(DISTINCT ooid.order_item_id) AS qtd_pedidos 
FROM olist_products_dataset opd
JOIN olist_order_items_dataset ooid ON ooid.product_id = opd.product_id
JOIN olist_orders_dataset ood ON ood.order_id = ooid.order_id 
GROUP BY categoria
ORDER BY qtd_pedidos DESC
LIMIT 5;

-- Existem categorias com alto preço médio, mas com volume extremamente baixo de vendas?
SELECT opd.product_category_name AS categoria, COUNT(ooid.order_item_id) AS total_vendas, ROUND(AVG(ooid.price), 2) AS preco_medio_produto, ROUND(SUM(ooid.price), 2) AS receita_total
FROM olist_order_items_dataset ooid
JOIN olist_products_dataset opd ON ooid.product_id = opd.product_id
WHERE opd.product_category_name IS NOT NULL
GROUP BY categoria
HAVING total_vendas < 100
ORDER BY preco_medio_produto DESC
LIMIT 10;

-- Quais produtos ou categorias de produtos costumam ser comprados juntos no mesmo pedido?
SELECT p1.product_category_name AS categoria_1, p2.product_category_name AS categoria_2, COUNT(DISTINCT i1.order_id) AS total_pedidos_juntos
FROM olist_order_items_dataset i1
JOIN olist_order_items_dataset i2 ON i1.order_id = i2.order_id 
JOIN olist_products_dataset p1 ON i1.product_id = p1.product_id
JOIN olist_products_dataset p2 ON i2.product_id = p2.product_id
WHERE 
    p1.product_category_name < p2.product_category_name
    AND p1.product_category_name IS NOT NULL
    AND p2.product_category_name IS NOT NULL
GROUP BY categoria_1, categoria_2
ORDER BY total_pedidos_juntos DESC
LIMIT 5;

--O valor do frete representa qual proporção do valor total do pedido em regiões afastadas vs. capitais?
WITH proporcao_frete_pedidos AS (
	SELECT ood.order_id, ood.customer_id, SUM(ooid.price) AS total_produtos, SUM(ooid.freight_value) AS total_frete, (SUM(ooid.price) + SUM(ooid.freight_value)) AS total_pedido,
	((SUM(ooid.freight_value) * 100.0) / (SUM(ooid.price) + SUM(ooid.freight_value))) AS pct_frete_pedido, ocd.customer_city, ocd.customer_state,
	
	CASE 
		WHEN LOWER(ocd.customer_city) IN (
				'sao paulo', 'rio de janeiro', 'belo horizonte', 'brasilia', 'curitiba',
				'porto alegre', 'salvador', 'recife', 'fortaleza', 'goiania',
				'belem', 'manaus', 'vitoria', 'florianopolis', 'sao luis',
				'maceio', 'natal', 'teresina', 'joao pessoa', 'aracaju',
				'campo grande', 'cuiaba', 'porto velho', 'macapa', 'rio branco',
				'palmas', 'boa vista'
			) THEN 'Capitais'
			ELSE 'Interior / Regiões Afetadas'
		END AS tipo_regiao		
	FROM olist_orders_dataset ood 
	JOIN olist_customers_dataset ocd ON ocd.customer_id = ood.customer_id
	JOIN olist_order_items_dataset ooid ON ooid.order_id = ood.order_id 
	WHERE ood.order_status = 'delivered'
    GROUP BY ood.order_id, ocd.customer_state, ocd.customer_city
)

SELECT tipo_regiao, COUNT(order_id) AS total_pedidos, ROUND(AVG(total_produtos), 2) AS ticket_medio_produtos, ROUND(AVG(total_frete), 2) AS frete_medio,
	ROUND(AVG(pct_frete_pedido), 2) AS pct_medio_frete_por_pedido
FROM proporcao_frete_pedidos
GROUP BY tipo_regiao;

--Existe correlação entre atrasos na entrega do pedido e notas baixas nas avaliações do produto? 
WITH entrega_review_pedidos AS (
	SELECT oord.order_id, oord.review_score, ood.order_delivered_customer_date, ood.order_estimated_delivery_date,
	CASE
		WHEN ood.order_delivered_customer_date > ood.order_estimated_delivery_date THEN 'Atrasado'
		ELSE 'No Prazo'
	END AS situacao_entrega
FROM olist_order_reviews_dataset oord 
JOIN olist_orders_dataset ood ON ood.order_id = oord.order_id
WHERE ood.order_delivered_customer_date IS NOT NULL
)

SELECT situacao_entrega, ROUND(AVG(review_score), 2) AS media_review, COUNT(DISTINCT order_id) AS qtd_pedidos, SUM(CASE WHEN review_score <= 2 THEN 1 ELSE 0 END) AS qtd_avaliacoes_baixas,
	ROUND((SUM(CASE WHEN review_score <= 2 THEN 1 ELSE 0 END) * 100.0) / COUNT(DISTINCT order_id), 2) AS pct_notas_baixas
FROM entrega_review_pedidos 
GROUP BY situacao_entrega;

--Qual a distribuição dos métodos de pagamento (cartão de crédito, boleto, PIX) por região?
SELECT customer_state AS estado, payment_type AS tipo_pagamento, COUNT(DISTINCT oopd.order_id) AS total_pedidos, ROUND(SUM(oopd.payment_value), 2) AS valor_total_pago 
FROM olist_order_payments_dataset oopd
JOIN olist_orders_dataset ood ON ood.order_id = oopd.order_id
JOIN olist_customers_dataset ocd ON ocd.customer_id = ood.customer_id
WHERE ood.order_status = 'delivered'
GROUP BY ocd.customer_state, oopd.payment_type
ORDER BY ocd.customer_state, total_pedidos DESC;



