#!/bin/sh
OUTPUT_PATH=supportbundle.tar.gz
set -e

echo "Finding support bundle pod"
pod=$(kubectl get pods --selector=tier=support-bundle -o jsonpath='{.items[*].metadata.name}')

echo "Collecting from pod ${pod}"
/bin/sh -c "kubectl exec ${pod} -- support-bundle generate --customer-id={{repl Installation "customer_id"}} --out - --quiet --yes-upload " > $OUTPUT_PATH

echo "Bundle generated at ${OUTPUT_PATH}"
