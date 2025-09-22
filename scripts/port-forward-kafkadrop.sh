#!/bin/bash
set -e

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

# Verificar si Kafdrop esta corriendo
echo -e "${BLUE}🔍 Verificando estado de Kafdrop...${NC}"
POD_STATUS=$(kubectl get pods -n "$KAFDROP_NAMESPACE" -l app=kafdrop -o jsonpath='{.items[0].status.phase}' 2>/dev/null)

if [ "$POD_STATUS" != "Running" ]; then
    echo -e "${RED}❌ Kafdrop no esta corriendo en namespace: $KAFDROP_NAMESPACE${NC}"
    echo -e "   Estado actual: ${YELLOW}$POD_STATUS${NC}"
    echo ""
    echo -e "${YELLOW}💡 Ejecuta primero: ./scripts/deploy-kafdrop.sh${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Kafdrop esta corriendo${NC}"
echo -e "${BLUE}🔗 Iniciando port-forward para Kafdrop...${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "📊 Kafdrop estara disponible en: ${YELLOW}http://localhost:$LOCAL_PORT${NC}"
echo -e "🛑 Presiona ${YELLOW}Ctrl+C${NC} para detener"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Ejecutar port-forward
kubectl port-forward service/kafdrop-service "$LOCAL_PORT:9000" -n "$KAFDROP_NAMESPACE"