-- Gold Layer 

--- 3.1 Dimension Transaction Type

CREATE OR REPLACE TABLE `finance_dw.dim_transaction_type` AS
SELECT
  type AS transaction_type,
  DENSE_RANK() OVER (ORDER BY type) AS type_id
FROM (
  SELECT DISTINCT type
  FROM `finance_dw.paysim_clean`
);

--- 3.2 Dimension Date

CREATE OR REPLACE TABLE `finance_dw.dim_date` AS
SELECT DISTINCT
  DATE(transaction_datetime) AS date,
  EXTRACT(YEAR FROM transaction_datetime) AS year,
  EXTRACT(MONTH FROM transaction_datetime) AS month,
  EXTRACT(DAY FROM transaction_datetime) AS day,
  EXTRACT(DAYOFWEEK FROM transaction_datetime) AS day_of_week
FROM `finance_dw.paysim_clean`;


--- 3.3 Dimension Account

CREATE OR REPLACE TABLE `finance_dw.dim_account` AS
SELECT DISTINCT
  nameOrig AS account_id
FROM `finance_dw.paysim_clean`;