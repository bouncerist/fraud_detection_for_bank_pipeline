CREATE TABLE IF NOT EXISTS fraud_alerts (
    alert_id BIGSERIAL PRIMARY KEY,
    transaction_id BIGINT NOT NULL,
    client_id INT NOT NULL,
    card_id INT NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    merchant_id INT NOT NULL,
    transaction_date TIMESTAMP NOT NULL,
    risk_score DECIMAL(3,2) NOT NULL,
    risk_reasons TEXT NOT NULL,
    alert_level VARCHAR(10) DEFAULT 'medium',
    status VARCHAR(20) DEFAULT 'new',
    created_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Europe/Moscow')
);