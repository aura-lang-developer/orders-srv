#!/usr/bin/env bash
set -e

# ==============================================================================
# Script de Ejecución Rápida - Microservicio Hexagonal en Aura Lang
# ==============================================================================

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
cd "$DIR"

echo "================================================================================"
echo "  🔷 INICIALIZANDO MICROSERVICIO HEXAGONAL EN AURA (GOLANG IDIOMATIC STYLE)"
echo "================================================================================"

# 1. Ejecución de Pruebas Unitarias
echo ""
echo ">> [1/3] Ejecutando Pruebas Unitarias..."
aurac run tests/order_service_test.aura

# 2. Ejecución de Pruebas de Integración
echo ""
echo ">> [2/3] Ejecutando Pruebas de Integración..."
aurac run tests/integration_test.aura

# 3. Lanzamiento del Servidor
echo ""
echo ">> [3/3] Lanzando Servidor HTTP REST (Composition Root)..."
aurac run cmd/server/main.aura
