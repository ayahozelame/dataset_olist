#  Diagnóstico Estratégico de E-commerce: Vendas, Logística e Comportamento do Cliente (Dataset Olist)

**Analista de Dados:** Ayah Ozelame Al Khaldi  
**Ferramentas:** SQLite, DBeaver, Power BI

**Competência:** Setembro / 2026  


##  Visão Geral do Projeto
Este projeto realiza uma análise *end-to-end* sobre a operação de e-commerce brasileiro utilizando o dataset público da **Olist**. O objetivo foi identificar gargalos na malha logística nacional, mensurar o impacto de prazos na satisfação do cliente (NPS) e segmentar a base de compradores via **Matriz RFM**, transformando dados brutos em direcionamentos executivos de negócio.


##  Estrutura do Repositório

* `sql/01_exploratory_queries.sql`: Consultas de saúde do negócio, faturamento acumulado, AOV e distribuição geográfica.
* `sql/02_business_insights.sql`: Performance de categorias, cálculo da métrica de frete por macrorregião e impacto do atraso nas avaliações.
* `sql/03_rfm_cohort_analysis.sql`: Segmentação RFM avançada utilizando `julianday()` e `NTILE(4)`.
* `docs/RELATORIO_EXECUTIVO_OLIST.pdf`: Relatório final pronto para apresentação executiva.


##  Principais Insights Extraídos

### 1. Assimetria Regional de Frete e Impacto Logístico
* **Fato:** A maior parte dos *sellers* está concentrada na região Sudeste.
* **Impacto:** O frete representa em média **28,34%** do valor do pedido no **Norte** e **26,33%** no **Nordeste**, em contraste com apenas **1,95%** no **Sudeste**.
* **Recomendação:** Atrair parceiros regionais e estabelecer pontos de *fulfillment* no Norte/Nordeste para reduzir o abandono de carrinho.

### 2. Atraso na Entrega vs. Satisfação do Cliente (NPS)
* Pedidos entregues **no prazo** mantêm média de avaliação superior a **4,2 estrelas** (61% de notas 5).
* Pedidos **atrasados** registram mais de **54% de notas baixas (1 e 2 estrelas)**, sendo que a nota 1 sozinha representa **46%** das avaliações desse grupo, sobrecarregando o suporte.

### 3. Segmentação RFM (Recência, Frequência e Valor)
* Mapeamento da base de clientes identificando alto volume de compras únicas (baixo LTV).
* Definição de réguas de relacionamento automatizadas e campanhas de *win-back* para o segmento **Em Risco** e tratamento exclusivo para o segmento **VIP / Campeões**.


##  Relatório Executivo
O relatório completo em PDF contendo os gráficos detalhados do Power BI e as matrizes de recomendação pode ser acessado na pasta `/docs`.
