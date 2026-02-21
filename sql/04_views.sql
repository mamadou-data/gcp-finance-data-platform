---  Créons des vues analytiques

--- 🔹 Vue KPI fraude

CREATE OR REPLACE VIEW `finance_dw.v_fraud_rate_by_type` AS
SELECT
  t.transaction_type,
  COUNT(*) AS total_transactions,
  SUM(f.isFraud) AS fraud_count,
  ROUND(SUM(f.isFraud)/COUNT(*)*100,4) AS fraud_rate_pct
FROM `finance_dw.fact_transactions` f
JOIN `finance_dw.dim_transaction_type` t
ON f.type_id = t.type_id
GROUP BY t.transaction_type;


--- 🔹 Vue Volume journalier

CREATE OR REPLACE VIEW `finance_dw.v_daily_volume` AS
SELECT
  DATE(transaction_datetime) AS transaction_date,
  COUNT(*) AS total_transactions,
  SUM(amount) AS total_amount
FROM `finance_dw.fact_transactions`
GROUP BY transaction_date;