--- 4 Table de faits

CREATE TABLE `finance_dw.fact_transactions`
PARTITION BY DATE(transaction_datetime) AS
SELECT
  p.transaction_datetime,
  d.type_id,
  p.amount,
  p.isFraud
FROM `finance_dw.paysim_clean` p
JOIN `finance_dw.dim_transaction_type` d
ON p.type = d.transaction_type;

--- on Ajouter le clustering après
CREATE TABLE `finance_dw.fact_transactions_clustered`
PARTITION BY DATE(transaction_datetime)
CLUSTER BY type_id AS
SELECT * FROM `finance_dw.fact_transactions`;

DROP TABLE `finance_dw.fact_transactions`;

ALTER TABLE `finance_dw.fact_transactions_clustered`
RENAME TO `fact_transactions`;

