#!/bin/bash
set -e

# ============================================
# Script para verificar conectividad con Kafka
# ============================================

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Cargar configuracion
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/kafdrop.env"

if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}❌ Error: No se encuentra el archivo de configuracion: $CONFIG_FILE${NC}"
    exit 1
fi

source "$CONFIG_FILE"

echo -e "${BLUE}🔍 Verificando conectividad con Kafka${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# 1. Verificar que el namespace de Kafka existe
echo -e "${BLUE}1. Verificando namespace de Kafka...${NC}"
if kubectl get namespace "$KAFKA_NAMESPACE" &> /dev/null; then
    echo -e "${GREEN}   ✅ Namespace '$KAFKA_NAMESPACE' existe${NC}"
else
    echo -e "${RED}   ❌ Namespace '$KAFKA_NAMESPACE' no existe${NC}"
    echo -e "${YELLOW}   Namespaces disponibles:${NC}"
    kubectl get namespaces
    exit 1
fi

# 2. Verificar servicio de Kafka
echo -e "${BLUE}2. Verificando servicio de Kafka...${NC}"
if kubectl get service "$KAFKA_SERVICE_NAME" -n "$KAFKA_NAMESPACE" &> /dev/null; then
    echo -e "${GREEN}   ✅ Servicio '$KAFKA_SERVICE_NAME' encontrado${NC}"
    kubectl get service "$KAFKA_SERVICE_NAME" -n "$KAFKA_NAMESPACE" --no-headers
else
    echo -e "${RED}   ❌ Servicio '$KAFKA_SERVICE_NAME' no encontrado en namespace '$KAFKA_NAMESPACE'${NC}"
    echo -e "${YELLOW}   Servicios disponibles en '$KAFKA_NAMESPACE':${NC}"
    kubectl get services -n "$KAFKA_NAMESPACE"
    exit 1
fi

# 3. Verificar pods de Kafka
echo -e "${BLUE}3. Verificando pods de Kafka...${NC}"
KAFKA_PODS=$(kubectl get pods -n "$KAFKA_NAMESPACE" -l "strimzi.io/name=$KAFKA_SERVICE_NAME" --no-headers 2>/dev/null | wc -l)
if [ "$KAFKA_PODS" -gt 0 ]; then
    echo -e "${GREEN}   ✅ Encontrados $KAFKA_PODS pods de Kafka${NC}"
    kubectl get pods -n "$KAFKA_NAMESPACE" -l "strimzi.io/name=$KAFKA_SERVICE_NAME" --no-headers
else
    echo -e "${YELLOW}   ⚠️  No se encontraron pods con label 'strimzi.io/name=$KAFKA_SERVICE_NAME'${NC}"
    echo -e "${YELLOW}   Buscando todos los pods en '$KAFKA_NAMESPACE':${NC}"
    kubectl get pods -n "$KAFKA_NAMESPACE"
fi

# 4. Test de resolucion DNS desde el namespace de Kafdrop
echo -e "${BLUE}4. Probando resolucion DNS...${NC}"
DNS_TEST=$(kubectl run dns-test-$RANDOM --image=busybox:1.28 --rm -i --restart=Never --namespace="$KAFDROP_NAMESPACE" -- \
    nslookup "$KAFKA_SERVICE_NAME.$KAFKA_NAMESPACE.svc.cluster.local" 2>&1)

if echo "$DNS_TEST" | grep -q "can't resolve"; then
    echo -e "${RED}   ❌ No se puede resolver el DNS de Kafka${NC}"
    echo -e "${YELLOW}   Output: $DNS_TEST${NC}"
else
    echo -e "${GREEN}   ✅ DNS resuelve correctamente${NC}"
fi

# 5. Verificar conectividad al puerto
echo -e "${BLUE}5. Probando conectividad al puerto $KAFKA_PORT...${NC}"
CONNECTIVITY_TEST=$(kubectl run connectivity-test-$RANDOM --image=busybox:1.28 --rm -i --restart=Never --namespace="$KAFDROP_NAMESPACE" -- \
    sh -c "echo '' | nc -w 2 $KAFKA_SERVICE_NAME.$KAFKA_NAMESPACE.svc.cluster.local $KAFKA_PORT && echo 'Connected' || echo 'Failed'" 2>&1 | tail -n 1)

if [ "$CONNECTIVITY_TEST" == "Connected" ]; then
    echo -e "${GREEN}   ✅ Conectividad exitosa al puerto $KAFKA_PORT${NC}"
else
    echo -e "${RED}   ❌ No se puede conectar al puerto $KAFKA_PORT${NC}"
    echo -e "${YELLOW}   Verifica que Kafka este escuchando en el puerto correcto${NC}"
fi

# 6. Listar topics (si hay un pod de Kafka disponible)
echo -e "${BLUE}6. Intentando listar topics de Kafka...${NC}"
KAFKA_POD=$(kubectl get pods -n "$KAFKA_NAMESPACE" -l "strimzi.io/name=${KAFKA_SERVICE_NAME%-*}-kafka" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -n "$KAFKA_POD" ]; then
    echo -e "${YELLOW}   Usando pod: $KAFKA_POD${NC}"
    kubectl exec -n "$KAFKA_NAMESPACE" "$KAFKA_POD" -- /opt/kafka/bin/kafka-topics.sh \
        --bootstrap-server localhost:9092 --list 2>/dev/null | head -10 || {
        echo -e "${YELLOW}   No se pudieron listar los topics${NC}"
    }
else
    echo -e "${YELLOW}   No se encontro un pod de Kafka para ejecutar comandos${NC}"
fi

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}📋 Resumen de Configuracion:${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  Kafka Namespace:  ${YELLOW}$KAFKA_NAMESPACE${NC}"
echo -e "  Kafka Service:    ${YELLOW}$KAFKA_SERVICE_NAME${NC}"
echo -e "  Kafka Port:       ${YELLOW}$KAFKA_PORT${NC}"
echo -e "  Kafka Brokers:    ${YELLOW}$KAFKA_BROKERS${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"