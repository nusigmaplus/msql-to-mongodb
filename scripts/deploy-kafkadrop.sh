#!/bin/bash
set -e

# ============================================
# Script de despliegue de Kafdrop con configuracion flexible
# ============================================

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Cargar configuracion desde archivo .env
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/kafdrop.env"

# Verificar si existe el archivo de configuracion
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}❌ Error: No se encuentra el archivo de configuracion: $CONFIG_FILE${NC}"
    echo -e "${YELLOW}💡 Crea el archivo con: cp scripts/kafdrop.env.example scripts/kafdrop.env${NC}"
    exit 1
fi

# Cargar variables de configuracion
echo -e "${BLUE}📋 Cargando configuracion desde: $CONFIG_FILE${NC}"
source "$CONFIG_FILE"

# Mostrar configuracion actual
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}🚀 Configuracion de Kafdrop:${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  📦 Namespace Kafdrop: ${YELLOW}$KAFDROP_NAMESPACE${NC}"
echo -e "  🎯 Kafka Namespace:   ${YELLOW}$KAFKA_NAMESPACE${NC}"
echo -e "  🔌 Kafka Brokers:     ${YELLOW}$KAFKA_BROKERS${NC}"
echo -e "  🖼️  Imagen:            ${YELLOW}$KAFDROP_IMAGE${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Confirmar antes de proceder
read -p "¿Continuar con esta configuracion? (y/n): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}⚠️  Despliegue cancelado${NC}"
    exit 0
fi

# Verificar que el servicio de Kafka existe
echo -e "${BLUE}🔍 Verificando servicio de Kafka...${NC}"
if kubectl get service "$KAFKA_SERVICE_NAME" -n "$KAFKA_NAMESPACE" &> /dev/null; then
    echo -e "${GREEN}✅ Servicio de Kafka encontrado${NC}"
    kubectl get service "$KAFKA_SERVICE_NAME" -n "$KAFKA_NAMESPACE"
else
    echo -e "${RED}❌ No se encuentra el servicio de Kafka: $KAFKA_SERVICE_NAME en namespace: $KAFKA_NAMESPACE${NC}"
    echo -e "${YELLOW}💡 Servicios disponibles en $KAFKA_NAMESPACE:${NC}"
    kubectl get services -n "$KAFKA_NAMESPACE"
    exit 1
fi

# Crear namespace si no existe
echo -e "${BLUE}📍 Preparando namespace: $KAFDROP_NAMESPACE${NC}"
kubectl create namespace "$KAFDROP_NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

# Crear ConfigMap con la configuracion actual
echo -e "${BLUE}⚙️  Creando ConfigMap...${NC}"
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: kafdrop-config
  namespace: $KAFDROP_NAMESPACE
data:
  kafka.brokers: "$KAFKA_BROKERS"
  kafdrop.args: "$KAFDROP_ARGS"
EOF

# Crear Deployment
echo -e "${BLUE}📦 Desplegando Kafdrop...${NC}"
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kafdrop
  namespace: $KAFDROP_NAMESPACE
  labels:
    app: kafdrop
spec:
  replicas: 1
  selector:
    matchLabels:
      app: kafdrop
  template:
    metadata:
      labels:
        app: kafdrop
    spec:
      containers:
      - name: kafdrop
        image: $KAFDROP_IMAGE
        ports:
        - containerPort: 9000
          name: http
        env:
        - name: KAFKA_BROKERCONNECT
          valueFrom:
            configMapKeyRef:
              name: kafdrop-config
              key: kafka.brokers
        - name: JVM_OPTS
          value: "$KAFDROP_JVM_OPTS"
        - name: SERVER_SERVLET_CONTEXTPATH
          value: "$KAFDROP_SERVER_CONTEXT"
        - name: CMD_ARGS
          valueFrom:
            configMapKeyRef:
              name: kafdrop-config
              key: kafdrop.args
        resources:
          requests:
            memory: "$KAFDROP_MEMORY_REQUEST"
            cpu: "$KAFDROP_CPU_REQUEST"
          limits:
            memory: "$KAFDROP_MEMORY_LIMIT"
            cpu: "$KAFDROP_CPU_LIMIT"
        livenessProbe:
          httpGet:
            path: /
            port: 9000
          initialDelaySeconds: 60
          periodSeconds: 30
          timeoutSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 9000
          initialDelaySeconds: 30
          periodSeconds: 15
          timeoutSeconds: 10
EOF

# Crear Service
echo -e "${BLUE}🌐 Creando Service...${NC}"
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: kafdrop-service
  namespace: $KAFDROP_NAMESPACE
  labels:
    app: kafdrop
spec:
  type: ClusterIP
  selector:
    app: kafdrop
  ports:
  - name: http
    port: 9000
    targetPort: 9000
    protocol: TCP
EOF

# Esperar a que el pod este listo
echo -e "${BLUE}⏳ Esperando a que Kafdrop este listo...${NC}"
kubectl wait --for=condition=ready pod -l app=kafdrop -n "$KAFDROP_NAMESPACE" --timeout=120s || {
    echo -e "${YELLOW}⚠️  Timeout esperando el pod. Verificando estado...${NC}"
    kubectl get pods -n "$KAFDROP_NAMESPACE" -l app=kafdrop
    echo -e "${YELLOW}Logs del pod:${NC}"
    kubectl logs -n "$KAFDROP_NAMESPACE" -l app=kafdrop --tail=50
    exit 1
}

# Verificar deployment
echo -e "${GREEN}✅ Verificando deployment...${NC}"
kubectl get pods -n "$KAFDROP_NAMESPACE" -l app=kafdrop
kubectl get services -n "$KAFDROP_NAMESPACE" -l app=kafdrop

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}🎉 Kafdrop desplegado exitosamente!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "📊 Para acceder a Kafdrop, ejecuta:"
echo -e "   ${YELLOW}./scripts/port-forward-kafdrop.sh${NC}"
echo ""
echo -e "🔍 O manualmente:"
echo -e "   ${YELLOW}kubectl port-forward service/kafdrop-service $LOCAL_PORT:9000 -n $KAFDROP_NAMESPACE${NC}"
echo ""
echo -e "🌐 Luego abre en tu navegador:"
echo -e "   ${YELLOW}http://localhost:$LOCAL_PORT${NC}"
echo ""
echo -e "📌 Topic CDC a monitorear:"
echo -e "   ${YELLOW}sqlserver-demo.DebeziumDemoDB.dbo.Products${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"