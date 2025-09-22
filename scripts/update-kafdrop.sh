#!/bin/bash
set -e

# ============================================
# Script para actualizar la configuracion de Kafdrop sin re-desplegar
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

echo -e "${BLUE}🔄 Actualizando configuracion de Kafdrop...${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  📦 Namespace: ${YELLOW}$KAFDROP_NAMESPACE${NC}"
echo -e "  🔌 Nuevos Brokers: ${YELLOW}$KAFKA_BROKERS${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Actualizar ConfigMap
echo -e "${BLUE}⚙️  Actualizando ConfigMap...${NC}"
kubectl create configmap kafdrop-config \
    --from-literal=kafka.brokers="$KAFKA_BROKERS" \
    --from-literal=kafdrop.args="$KAFDROP_ARGS" \
    --dry-run=client -o yaml | kubectl apply -n "$KAFDROP_NAMESPACE" -f -

# Reiniciar el deployment para aplicar cambios
echo -e "${BLUE}♻️  Reiniciando Kafdrop...${NC}"
kubectl rollout restart deployment/kafdrop -n "$KAFDROP_NAMESPACE"

# Esperar a que el rollout termine
echo -e "${BLUE}⏳ Esperando a que se complete el reinicio...${NC}"
kubectl rollout status deployment/kafdrop -n "$KAFDROP_NAMESPACE" --timeout=120s

echo -e "${GREEN}✅ Configuracion actualizada exitosamente!${NC}"
echo ""
echo -e "📊 Para acceder a Kafdrop con la nueva configuracion:"
echo -e "   ${YELLOW}./scripts/port-forward-kafdrop.sh${NC}"