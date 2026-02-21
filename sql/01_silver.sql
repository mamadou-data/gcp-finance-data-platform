--- Silver Layer (Clean + Date)

CREATE OR REPLACE TABLE `finance_dw.paysim_clean` AS
SELECT
  step,
  TIMESTAMP_ADD(TIMESTAMP('2026-01-01'), INTERVAL step HOUR) AS transaction_datetime,
  type,
  amount,
  nameOrig,
  oldbalanceOrg,
  newbalanceOrig,
  nameDest,
  oldbalanceDest,
  newbalanceDest,
  isFraud,
  isFlaggedFraud
FROM `finance_dw.paysim_raw`
WHERE amount > 0;
