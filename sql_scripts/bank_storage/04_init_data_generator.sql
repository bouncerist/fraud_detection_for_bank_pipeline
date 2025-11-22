CREATE OR REPLACE FUNCTION public.generate_bank_data(clients_count integer DEFAULT 1000, transactions_multiplier integer DEFAULT 5)
 RETURNS TABLE(clients_generated bigint, cards_generated bigint, transactions_generated bigint, details_generated bigint, total_clients bigint, total_cards bigint, total_transactions bigint)
 LANGUAGE plpgsql
DECLARE
    cards_count INT;
    transactions_count INT;
    existing_clients BIGINT;
    existing_cards BIGINT;
    existing_transactions BIGINT;
    card_type_ids INT[];
    merchant_ids INT[];
    new_clients_count BIGINT;
    new_cards_count BIGINT;
BEGIN
    RAISE NOTICE 'Starting data generation: % new clients, %x transactions',
        clients_count, transactions_multiplier;

    SELECT COUNT(*) INTO existing_clients FROM clients;
    SELECT COUNT(*) INTO existing_cards FROM cards;
    SELECT COUNT(*) INTO existing_transactions FROM transactions;

    RAISE NOTICE 'Existing data: % clients, % cards, % transactions',
        existing_clients, existing_cards, existing_transactions;

    IF NOT EXISTS (SELECT 1 FROM card_types) THEN
        RAISE NOTICE 'Generating card types...';
        INSERT INTO card_types (card_type, max_limit, currency) VALUES
        ('debit', 500000.00, 'RUB'),
        ('credit', 300000.00, 'RUB'),
        ('premium', 1000000.00, 'RUB'),
        ('corporate', 2000000.00, 'RUB');
    ELSE
        RAISE NOTICE 'Card types already exist, skipping...';
    END IF;

    SELECT ARRAY_AGG(id) INTO card_type_ids FROM card_types;
    RAISE NOTICE 'Available card types: %', card_type_ids;

    IF NOT EXISTS (SELECT 1 FROM merchants) THEN
        RAISE NOTICE 'Generating merchants...';
        INSERT INTO merchants (name, category, country) VALUES
        ('Магнит', 'food', 'RUS'),
        ('Пятерочка', 'food', 'RUS'),
        ('Лукойл', 'transport', 'RUS'),
        ('МВидео', 'electronics', 'RUS'),
        ('Яндекс.Такси', 'services', 'RUS'),
        ('СберМаркет', 'food', 'RUS'),
        ('Аптека', 'health', 'RUS'),
        ('Steam', 'entertainment', 'USA'),
        ('Amazon', 'ecommerce', 'USA'),
        ('Online Casino', 'gambling', 'CY');
    ELSE
        RAISE NOTICE 'Merchants already exist, skipping...';
    END IF;

    SELECT ARRAY_AGG(id) INTO merchant_ids FROM merchants;
    RAISE NOTICE 'Available merchants: %', merchant_ids;

    RAISE NOTICE 'Generating % new clients...', clients_count;
    INSERT INTO clients (last_name, first_name, middle_name, country)
    SELECT
        'LastName' || (existing_clients + i) as last_name,
        'FirstName' || (existing_clients + i) as first_name,
        CASE WHEN random() > 0.2 THEN 'MiddleName' || (existing_clients + i) ELSE NULL END as middle_name,
        CASE
            WHEN random() > 0.1 THEN 'RUS'
            ELSE (ARRAY['USA','CHN','JPN'])[floor(random()*3)+1]
        END as country
    FROM generate_series(1, clients_count) as i;

    SELECT COUNT(*) INTO new_clients_count FROM clients WHERE id > existing_clients;
    RAISE NOTICE 'Actually added: % new clients', new_clients_count;

    cards_count := new_clients_count * 2;
    RAISE NOTICE 'Generating ~% new cards...', cards_count;

    INSERT INTO cards (client_id, card_type_id, card_number, cvv, expiry_date, daily_limit)
    SELECT
        c.id as client_id,
        card_type_ids[floor(random() * array_length(card_type_ids, 1))::int + 1] as card_type_id,
        lpad((random() * 10000000000000000)::bigint::text, 16, '0') as card_number,
        lpad((random() * 1000)::int::text, 3, '0') as cvv,
        CURRENT_DATE + (random() * 1825)::int as expiry_date,
        (ARRAY[50000, 100000, 150000, 200000])[floor(random()*4)+1] as daily_limit
    FROM
        (SELECT id FROM clients WHERE id > existing_clients) c
    CROSS JOIN generate_series(1, 2) as card_num;

    SELECT COUNT(*) INTO new_cards_count FROM cards WHERE id > existing_cards;
    RAISE NOTICE 'Actually added: % new cards', new_cards_count;

    transactions_count := clients_count * transactions_multiplier;
    RAISE NOTICE 'Generating ~% new transactions...', transactions_count;

    INSERT INTO transactions (client_id, merchant_id, card_id, amount, transaction_date, status)
    SELECT
        cards.client_id,
        merchant_ids[floor(random() * array_length(merchant_ids, 1))::int + 1] as merchant_id,
        cards.id as card_id,
        round((random() * 100000 + 10)::numeric, 2) as amount,
        CURRENT_TIMESTAMP - (random() * 90 * 24 * 60 * 60)::int * interval '1 second' as transaction_date,
        'completed' as status
    FROM (
        SELECT generate_series(1, transactions_count) as transaction_num
    ) as series
    CROSS JOIN LATERAL (
        SELECT id, client_id
        FROM cards
        WHERE id > max_card_id_before
        ORDER BY random()
        LIMIT 1
    ) as cards;

    RAISE NOTICE 'Generating transaction details for new transactions...';
    INSERT INTO transaction_details (transaction_id, description, location, device_info, ip_address)
    SELECT
        t.id as transaction_id,
        'Transaction from ' || (ARRAY['Магнит','Пятерочка','Лукойл','МВидео','Яндекс.Такси'])[floor(random()*5)+1] as description,
        (ARRAY['Москва','Санкт-Петербург','Новосибирск','Екатеринбург','Казань'])[floor(random()*5)+1] as location,
        (ARRAY['mobile_app','web_browser','terminal','atm'])[floor(random()*4)+1] as device_info,
        ('192.168.' || floor(random()*255)::int || '.' || floor(random()*255)::int)::inet as ip_address
    FROM transactions t
    WHERE t.id > existing_transactions;

    RETURN QUERY
    SELECT
        new_clients_count::BIGINT as clients_generated,
        new_cards_count::BIGINT as cards_generated,
        transactions_count::BIGINT as transactions_generated,
        (SELECT COUNT(*) FROM transaction_details WHERE id > (SELECT COALESCE(MAX(id), 0) FROM transaction_details WHERE transaction_id <= existing_transactions))::BIGINT as details_generated,
        (SELECT COUNT(*) FROM clients)::BIGINT as total_clients,
        (SELECT COUNT(*) FROM cards)::BIGINT as total_cards,
        (SELECT COUNT(*) FROM transactions)::BIGINT as total_transactions;

    RAISE NOTICE 'Data generation completed!';
    RAISE NOTICE 'Total now: % clients, % cards, % transactions',
        (SELECT COUNT(*) FROM clients),
        (SELECT COUNT(*) FROM cards),
        (SELECT COUNT(*) FROM transactions);

END;