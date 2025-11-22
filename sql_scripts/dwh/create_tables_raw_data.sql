CREATE TABLE clients (
   id INTEGER,
   last_name VARCHAR(100) NOT NULL,
   first_name VARCHAR(100) NOT NULL,
   middle_name VARCHAR(100),
   country VARCHAR(3) NOT NULL,
   created_date DATE DEFAULT CURRENT_DATE
)
WITH (APPENDONLY=true, ORIENTATION=row, COMPRESSTYPE=zstd, COMPRESSLEVEL=2)
DISTRIBUTED BY (id);

CREATE TABLE merchants (
   id INTEGER,
   "name" VARCHAR(100) NOT NULL,
   category VARCHAR(50) NOT NULL,
   country VARCHAR(3) NOT NULL
)
WITH (APPENDONLY=true, ORIENTATION=row, COMPRESSTYPE=zstd, COMPRESSLEVEL=1)
DISTRIBUTED REPLICATED;

CREATE TABLE card_types (
   id INTEGER,
   card_type VARCHAR(50) NOT NULL,
   max_limit DECIMAL(15,2),
   currency VARCHAR(3) DEFAULT 'RUB'
)
WITH (APPENDONLY=true, ORIENTATION=row, COMPRESSTYPE=zstd, COMPRESSLEVEL=1)
DISTRIBUTED REPLICATED;

CREATE TABLE cards (
   id INTEGER,
   client_id INTEGER NOT NULL,
   card_type_id INTEGER NOT NULL,
   card_number VARCHAR(16) NOT NULL,
   cvv VARCHAR(3) NOT NULL,
   issue_date DATE DEFAULT CURRENT_DATE,
   expiry_date DATE NOT NULL,
   is_active BOOLEAN DEFAULT TRUE,
   daily_limit DECIMAL(15,2) DEFAULT 100000.00,
   current_daily_spent DECIMAL(15,2) DEFAULT 0
)
WITH (APPENDONLY=true, ORIENTATION=row, COMPRESSTYPE=zstd, COMPRESSLEVEL=2)
DISTRIBUTED BY (client_id);

CREATE TABLE transactions (
   id BIGINT,
   client_id INTEGER,
   merchant_id INTEGER,
   card_id INTEGER,
   amount DECIMAL(15,2) NOT NULL,
   currency VARCHAR(3) DEFAULT 'RUB',
   transaction_date TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Europe/Moscow'),
   status VARCHAR(20) DEFAULT 'completed'
)
WITH (APPENDONLY=true, ORIENTATION=row, COMPRESSTYPE=zstd, COMPRESSLEVEL=3)
DISTRIBUTED BY (client_id);

CREATE TABLE transaction_details (
   id INTEGER,
   transaction_id BIGINT NOT NULL,
   description VARCHAR(200),
   location VARCHAR(100),
   device_info VARCHAR(100),
   ip_address VARCHAR(45),
   created_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Europe/Moscow')
)
WITH (APPENDONLY=true, ORIENTATION=row, COMPRESSTYPE=zstd, COMPRESSLEVEL=2)
DISTRIBUTED BY (transaction_id);

CREATE TABLE fraud_alerts (
   alert_id BIGSERIAL,
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
)
WITH (APPENDONLY=true, ORIENTATION=row, COMPRESSTYPE=zstd, COMPRESSLEVEL=2)
DISTRIBUTED BY (client_id);