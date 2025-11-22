CREATE STREAM TRANSACTIONS_DEBEZIUM_STREAM
WITH (
    KAFKA_TOPIC = 'bank.public.transactions',
    VALUE_FORMAT = 'AVRO'
);

CREATE STREAM FRAUD_ALERTS_STREAM WITH (
    kafka_topic = 'fraud-alerts-avro',
    value_format = 'AVRO',
    partitions = 3
) AS
SELECT
    ID AS "transaction_id",
    CLIENT_ID AS "client_id",
    CARD_ID AS "card_id",
    AMOUNT AS "amount",
    MERCHANT_ID AS "merchant_id",
    TRANSACTION_DATE AS "transaction_date",
    (
        CASE WHEN AMOUNT > 50000 THEN 0.5 ELSE 0.0 END +
        CASE WHEN TRANSACTION_DATE LIKE '%T00:%' OR
                  TRANSACTION_DATE LIKE '%T01:%' OR
                  TRANSACTION_DATE LIKE '%T02:%' OR
                  TRANSACTION_DATE LIKE '%T03:%' OR
                  TRANSACTION_DATE LIKE '%T04:%' OR
                  TRANSACTION_DATE LIKE '%T05:%' OR
                  TRANSACTION_DATE LIKE '%T06:%'
             THEN 0.5 ELSE 0.0 END
    ) AS "risk_score",
    CONCAT_WS(',',
        CASE WHEN AMOUNT > 50000 THEN 'high_amount' ELSE NULL END,
        CASE WHEN TRANSACTION_DATE LIKE '%T00:%' OR
                  TRANSACTION_DATE LIKE '%T01:%' OR
                  TRANSACTION_DATE LIKE '%T02:%' OR
                  TRANSACTION_DATE LIKE '%T03:%' OR
                  TRANSACTION_DATE LIKE '%T04:%' OR
                  TRANSACTION_DATE LIKE '%T05:%' OR
                  TRANSACTION_DATE LIKE '%T06:%'
             THEN 'night_time' ELSE NULL END
    ) AS "risk_reasons",
    CASE
        WHEN (AMOUNT > 50000 AND (TRANSACTION_DATE LIKE '%T00:%' OR
                                  TRANSACTION_DATE LIKE '%T01:%' OR
                                  TRANSACTION_DATE LIKE '%T02:%' OR
                                  TRANSACTION_DATE LIKE '%T03:%' OR
                                  TRANSACTION_DATE LIKE '%T04:%' OR
                                  TRANSACTION_DATE LIKE '%T05:%' OR
                                  TRANSACTION_DATE LIKE '%T06:%')) THEN 'high'
        WHEN (AMOUNT > 50000 OR (TRANSACTION_DATE LIKE '%T00:%' OR
                                 TRANSACTION_DATE LIKE '%T01:%' OR
                                 TRANSACTION_DATE LIKE '%T02:%' OR
                                 TRANSACTION_DATE LIKE '%T03:%' OR
                                 TRANSACTION_DATE LIKE '%T04:%' OR
                                 TRANSACTION_DATE LIKE '%T05:%' OR
                                 TRANSACTION_DATE LIKE '%T06:%')) THEN 'medium'
        ELSE 'low'
    END AS "alert_level",
    'new' AS "status"
FROM TRANSACTIONS_DEBEZIUM_STREAM
WHERE AMOUNT > 50000 OR (TRANSACTION_DATE LIKE '%T00:%' OR
                         TRANSACTION_DATE LIKE '%T01:%' OR
                         TRANSACTION_DATE LIKE '%T02:%' OR
                         TRANSACTION_DATE LIKE '%T03:%' OR
                         TRANSACTION_DATE LIKE '%T04:%' OR
                         TRANSACTION_DATE LIKE '%T05:%' OR
                         TRANSACTION_DATE LIKE '%T06:%')
EMIT CHANGES;



