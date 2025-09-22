#!/bin/bash
set -e

# Obtener namespace actual
NAMESPACE=$(kubectl config view --minify --output 'jsonpath={..namespace}')
if [ -z "$NAMESPACE" ]; then
    NAMESPACE="default"
fi

echo "🔗 Iniciando port-forward para Kafdrop en namespace: $NAMESPACE"
echo "📊 Kafdrop estará disponible en: http://localhost:9000"
echo "🛑 Presiona Ctrl+C para detener"

kubectl port-forward service/kafdrop-service 9000:9000 -n $NAMESPACE