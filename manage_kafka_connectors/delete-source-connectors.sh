#!/bin/bash
echo "-----------------------------------------------------------------"
  echo "Deleting connector: src_dwh"
  curl -X DELETE http://localhost:8083/connectors/src_dwh
  echo -e "\n src_dwh deleted."