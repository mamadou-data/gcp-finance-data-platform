-------------------------------------  🧪 Data Quality Setup ---------------------------------------
---  🎯 Objectif : Créer :

--- ✅ Des contrôles qualité

--- ✅ Une table d’audit

--- ✅ Un statut PASS / FAIL

CREATE OR REPLACE TABLE `finance_dw.data_quality_audit` (
  run_timestamp TIMESTAMP,
  check_name STRING,
  check_value FLOAT64,
  threshold FLOAT64,
  status STRING
);

----- Contrôle 1 — Nombre de lignes cohérent

--- On vérifie que : fact_transactions = paysim_clean

INSERT INTO `finance_dw.data_quality_audit`
SELECT
  CURRENT_TIMESTAMP(),
  'row_count_consistency',
  fact_count,
  clean_count,
  CASE
    WHEN fact_count = clean_count THEN 'PASS'
    ELSE 'FAIL'
  END
FROM (
  SELECT
    (SELECT COUNT(*) FROM `finance_dw.fact_transactions`) AS fact_count,
    (SELECT COUNT(*) FROM `finance_dw.paysim_clean`) AS clean_count
);

--- Contrôle 2 — Null check sur amount

INSERT INTO `finance_dw.data_quality_audit`
SELECT
  CURRENT_TIMESTAMP(),
  'null_amount_check',
  COUNT(*),
  0,
  CASE
    WHEN COUNT(*) = 0 THEN 'PASS'
    ELSE 'FAIL'
  END
FROM `finance_dw.fact_transactions`
WHERE amount IS NULL;

--- Contrôle 3 — Taux de fraude réaliste

--- Dans PaySim, le taux est < 1%.  On fixe un seuil max à 5%

INSERT INTO `finance_dw.data_quality_audit`
SELECT
  CURRENT_TIMESTAMP(),
  'fraud_rate_threshold',
  fraud_rate,
  5,
  CASE
    WHEN fraud_rate < 5 THEN 'PASS'
    ELSE 'FAIL'
  END
FROM (
  SELECT
    ROUND(SUM(isFraud)/COUNT(*)*100,4) AS fraud_rate
  FROM `finance_dw.fact_transactions`
);

--- 4. Voir les résultats

SELECT *
FROM `finance_dw.data_quality_audit`
ORDER BY run_timestamp DESC;


------------------------------------------------ MONITORING ---------------------------------------
--- Table de monitoring des runs
CREATE OR REPLACE TABLE `finance_dw.pipeline_runs` (
  run_id STRING,
  start_time TIMESTAMP,
  end_time TIMESTAMP,
  status STRING,
  message STRING
);