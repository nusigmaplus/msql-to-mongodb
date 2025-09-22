#!/bin/bash
set -e

echo "🚀 Desplegando Kafdrop para monitoreo CDC..."

# Obtener namespace actual (donde se despliega la app)
NAMESPACE=$(kubectl config view --minify --output 'jsonpath={..namespace}')
if [ -z "$NAMESPACE" ]; then
    NAMESPACE="default"
fi

echo "📍 Desplegando en namespace: $NAMESPACE"

# Desplegar Kafdrop
kubectl apply -f k8s/kafdrop/configmap.yaml -n $NAMESPACE
kubectl apply -f k8s/kafdrop/deployment.yaml -n $NAMESPACE
kubectl apply -f k8s/kafdrop/service.yaml -n $NAMESPACE
kubectl apply -f k8s/kafdrop/ingress.yaml -n $NAMESPACE

# Verificar deployment
echo "✅ Verificando deployment..."
kubectl get pods -n $NAMESPACE -l app=kafdrop
kubectl get services -n $NAMESPACE -l app=kafdrop

echo "🎉 Kafdrop desplegado en namespace: $NAMESPACE"
echo "📊 Port-forward: kubectl port-forward service/kafdrop-service 9000:9000 -n $NAMESPACE"
echo "🔍 Monitorea tu topic: sqlserver-demo.DebeziumDemoDB.dbo.Products"