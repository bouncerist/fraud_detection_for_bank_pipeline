#!/bin/bash
DEFAULT_CONNECTORS=("dbz_src_dwh.json" "sink_connector_clients.json" "sink_connector_cards.json" "sink_connector_card_types.json" "sink_connector_transaction_details.json" "sink_connector_transactions.json" "sink_connector_merchants.json" "sink_connector_transaction_fraud.json")

CONNECTOR_FILES=("${@:-${DEFAULT_CONNECTORS[@]}}")
STATUS_CONNECTOR=${3:-$DEFAULT_STATUS_CONNECTOR}

register_connector() {
  local file=$1
  local connector_name=$(basename "$file" .json)

  curl -X POST -H "Content-Type: application/json" --data @"kafka/connectors/$file" http://localhost:8083/connectors
}

for CONNECTOR_FILE in "${CONNECTOR_FILES[@]}"; do
  register_connector "$CONNECTOR_FILE"
done
