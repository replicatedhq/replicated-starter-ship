#!/bin/sh
#
# Support bundle collection script for when
# there is no outbound internet from inside the cluster.
#
# For online installs, use troubleshoot.sh instead
#
OUTPUT_PATH=supportbundle.tar.gz
set -e

echo "Finding support bundle pod"
pod=$(kubectl get pods --selector=tier=support-bundle -o jsonpath='{.items[*].metadata.name}')

spec=$(cat <<EOF
specs:
- kubernetes.cluster-info:
    output_dir: /kubernetes/
- kubernetes.version:
    output_dir: /kubernetes/
- kubernetes.resources:
    namespace: {{repl ConfigOption "namespace"}}
    output_dir: /kubernetes/pods
    kind: Pod
- kubernetes.logs:
    namespace: {{repl ConfigOption "namespace"}}
    output_dir: /kubernetes/logs
    list_options:
      # update with your app name
      labelSelector: app=example-nginx
EOF
)

json=$(echo "$spec" | python -c 'import sys, yaml, json; json.dump(yaml.load(sys.stdin), sys.stdout)')
echo "Collecting from pod ${pod}"

/bin/sh -c "kubectl exec ${pod} -- support-bundle generate --skip-default --spec '${json}'  --out - --quiet " > $OUTPUT_PATH


echo Bundle generated at ${OUTPUT_PATH}



