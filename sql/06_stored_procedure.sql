--- Stored Procedure industrielle

--- On va créer une procédure qui : Exécute Silver, Recrée les dimensions, Recrée la fact, Lance les contrôles qualité et Écrit le statut dans pipeline_runs.

CREATE OR REPLACE PROCEDURE `finance_dw.sp_run_finance_pipeline`()
BEGIN

  DECLARE run_id STRING DEFAULT GENERATE_UUID();
  DECLARE start_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP();
  DECLARE fraud_rate FLOAT64;
  DECLARE fact_count INT64;
  DECLARE clean_count INT64;
  DECLARE final_status STRING DEFAULT 'SUCCESS';

  -- Log start
  INSERT INTO `finance_dw.pipeline_runs`
  VALUES (run_id, start_ts, NULL, 'RUNNING', 'Pipeline started');

  -- ======================
  -- SILVER
  -- ======================
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

  -- ======================
  -- DIMENSIONS
  -- ======================
  CREATE OR REPLACE TABLE `finance_dw.dim_transaction_type` AS
  SELECT
    type AS transaction_type,
    DENSE_RANK() OVER (ORDER BY type) AS type_id
  FROM (
    SELECT DISTINCT type
    FROM `finance_dw.paysim_clean`
  );

  -- ======================
  -- FACT
  -- ======================
  CREATE OR REPLACE TABLE `finance_dw.fact_transactions`
  PARTITION BY DATE(transaction_datetime)
  CLUSTER BY type_id AS
  SELECT
    p.transaction_datetime,
    d.type_id,
    p.amount,
    p.isFraud
  FROM `finance_dw.paysim_clean` p
  JOIN `finance_dw.dim_transaction_type` d
  ON p.type = d.transaction_type;

  -- ======================
  -- DATA QUALITY
  -- ======================
  SET fact_count = (SELECT COUNT(*) FROM `finance_dw.fact_transactions`);
  SET clean_count = (SELECT COUNT(*) FROM `finance_dw.paysim_clean`);
  SET fraud_rate = (
      SELECT ROUND(SUM(isFraud)/COUNT(*)*100,4)
      FROM `finance_dw.fact_transactions`
  );

  IF fact_count != clean_count THEN
    SET final_status = 'FAILED_ROW_COUNT';
  END IF;

  IF fraud_rate > 5 THEN
    SET final_status = 'FAILED_FRAUD_THRESHOLD';
  END IF;

  -- Log end
  UPDATE `finance_dw.pipeline_runs`
  SET end_time = CURRENT_TIMESTAMP(),
      status = final_status,
      message = 'Pipeline completed'
  WHERE run_id = run_id;

END;

--------------------------------------------- Exécuter le pipeline -------------------------------------

CALL `finance_dw.sp_run_finance_pipeline`();

--- Vérifier monitoring
SELECT *
FROM `finance_dw.pipeline_runs`
ORDER BY start_time DESC;
