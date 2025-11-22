CREATE OR REPLACE RULE upsert_rule_clients AS ON INSERT TO clients
WHERE EXISTS (
    SELECT 1 FROM clients WHERE clients.id = NEW.id
)
DO INSTEAD
    UPDATE clients
    SET last_name = NEW.last_name,
        first_name = NEW.first_name,
        middle_name = NEW.middle_name,
        country = NEW.country,
        created_date = NEW.created_date
    WHERE clients.id = NEW.id;

CREATE OR REPLACE RULE upsert_rule_merchants AS ON INSERT TO merchants
WHERE EXISTS (
    SELECT 1 FROM merchants WHERE merchants.id = NEW.id
)
DO INSTEAD
    UPDATE merchants
    SET name = NEW.name,
        category = NEW.category,
        country = NEW.country
    WHERE merchants.id = NEW.id;

CREATE OR REPLACE RULE upsert_rule_card_types AS ON INSERT TO card_types
WHERE EXISTS (
    SELECT 1 FROM card_types WHERE card_types.id = NEW.id
)
DO INSTEAD
    UPDATE card_types
    SET card_type = NEW.card_type,
        max_limit = NEW.max_limit,
        currency = NEW.currency
    WHERE card_types.id = NEW.id;

CREATE OR REPLACE RULE upsert_rule_cards AS ON INSERT TO cards
WHERE EXISTS (
    SELECT 1 FROM cards WHERE cards.id = NEW.id
)
DO INSTEAD
    UPDATE cards
    SET client_id = NEW.client_id,
        card_type_id = NEW.card_type_id,
        card_number = NEW.card_number,
        cvv = NEW.cvv,
        issue_date = NEW.issue_date,
        expiry_date = NEW.expiry_date,
        is_active = NEW.is_active,
        daily_limit = NEW.daily_limit,
        current_daily_spent = NEW.current_daily_spent
    WHERE cards.id = NEW.id;

CREATE OR REPLACE RULE upsert_rule_transactions AS ON INSERT TO transactions
WHERE EXISTS (
    SELECT 1 FROM transactions WHERE transactions.id = NEW.id
)
DO INSTEAD
    UPDATE transactions
    SET client_id = NEW.client_id,
        merchant_id = NEW.merchant_id,
        card_id = NEW.card_id,
        amount = NEW.amount,
        currency = NEW.currency,
        transaction_date = NEW.transaction_date,
        status = NEW.status
    WHERE transactions.id = NEW.id;

CREATE OR REPLACE RULE upsert_rule_transaction_details AS ON INSERT TO transaction_details
WHERE EXISTS (
    SELECT 1 FROM transaction_details WHERE transaction_details.id = NEW.id
)
DO INSTEAD
    UPDATE transaction_details
    SET transaction_id = NEW.transaction_id,
        description = NEW.description,
        location = NEW.location,
        device_info = NEW.device_info,
        ip_address = NEW.ip_address,
        created_at = NEW.created_at
    WHERE transaction_details.id = NEW.id;