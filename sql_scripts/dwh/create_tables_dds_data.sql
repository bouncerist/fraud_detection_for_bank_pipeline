CREATE SCHEMA IF NOT EXISTS analysis;

CREATE TABLE analysis.daily_fraud_summary (
    analysis_date DATE,
    country VARCHAR(3),
    merchant_category VARCHAR(50),
    total_alerts BIGINT,
    total_amount DECIMAL(15,2),
    avg_risk_score DECIMAL(3,2),
    high_risk_alerts BIGINT,
    medium_risk_alerts BIGINT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)
WITH (APPENDONLY=true, ORIENTATION=column, COMPRESSTYPE=zstd, COMPRESSLEVEL=2)
DISTRIBUTED BY (country);

CREATE TABLE analysis.card_type_fraud_effectiveness (
    analysis_date DATE,
    card_type VARCHAR(50),
    currency VARCHAR(3),
    max_limit DECIMAL(15,2),
    total_alerts BIGINT,
    total_transaction_volume BIGINT,
    fraud_to_transaction_ratio DECIMAL(5,4),
    avg_fraud_amount DECIMAL(15,2),
    max_fraud_amount DECIMAL(15,2),
    high_risk_ratio DECIMAL(5,4),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)
WITH (APPENDONLY=true, ORIENTATION=column, COMPRESSTYPE=zstd, COMPRESSLEVEL=2)
DISTRIBUTED BY (card_type);