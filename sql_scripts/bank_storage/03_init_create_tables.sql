CREATE TABLE clients (
    id SERIAL PRIMARY KEY,
    last_name VARCHAR(100) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    middle_name VARCHAR(100),
    country VARCHAR(3) NOT NULL,
    created_date DATE DEFAULT CURRENT_DATE
);

CREATE TABLE merchants (
    id SERIAL PRIMARY KEY,
    "name" VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL,
    country VARCHAR(3) NOT NULL
);

CREATE TABLE card_types (
    id SERIAL PRIMARY KEY,
    card_type VARCHAR(50) NOT NULL UNIQUE,
    max_limit DECIMAL(15,2),
    currency VARCHAR(3) DEFAULT 'RUB'
);

CREATE TABLE cards (
    id SERIAL PRIMARY KEY,
    client_id INT NOT NULL REFERENCES clients(id),
    card_type_id INT NOT NULL REFERENCES card_types(id),
    card_number VARCHAR(16) NOT NULL UNIQUE,
    cvv VARCHAR(3) NOT NULL,
    issue_date DATE DEFAULT CURRENT_DATE,
    "expiry_date" DATE NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    daily_limit DECIMAL(15,2) DEFAULT 100000.00,
    current_daily_spent DECIMAL(15,2) DEFAULT 0
);

CREATE TABLE transactions (
    id BIGSERIAL PRIMARY KEY,
    client_id INT REFERENCES clients(id),
    merchant_id INT REFERENCES merchants(id),
    card_id INT REFERENCES cards(id),
    amount DECIMAL(15,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'RUB',
    transaction_date TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Europe/Moscow'),
    "status" VARCHAR(20) DEFAULT 'completed'
);

CREATE TABLE transaction_details (
    id SERIAL PRIMARY KEY,
    transaction_id BIGINT NOT NULL REFERENCES transactions(id),
    "description" VARCHAR(200),
    "location" VARCHAR(100),
    device_info VARCHAR(100),
    ip_address INET,
    created_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Europe/Moscow')
);