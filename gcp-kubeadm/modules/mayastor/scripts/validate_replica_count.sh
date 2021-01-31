set -e
if [ "${MAYASTOR_REPLICAS}" -gt "${NUM_NODES}" ]; then
    echo "Variable mayastor_replicas cannot be greater than number of cluster nodes"
    exit 1
fi