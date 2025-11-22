#!/bin/bash
DEFAULT_CONNECTORS=("sink-transactions" "sink-transaction_details" "sink-transactions-fraud"
                    "sink-clients" "sink-merchants" "sink-card_types" "sink-cards")

CONNECTORS=("$@")
if [ ${#CONNECTORS[@]} -eq 0 ]; then
  CONNECTORS=("${DEFAULT_CONNECTORS[@]}")
fi

for CONNECTOR in "${CONNECTORS[@]}"; do
echo "-----------------------------------------------------------------"
  echo "Deleting connector: $CONNECTOR"
  curl -X DELETE http://localhost:8083/connectors/$CONNECTOR
  echo -e "\n $CONNECTOR deleted."
done