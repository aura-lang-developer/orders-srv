# ==============================================================================
# Makefile - Microservicio Hexagonal en Aura Lang (Estilo Golang)
# ==============================================================================

.PHONY: all build run test test-integration check fmt clean help

AURA_BIN ?= $(shell which aurac 2>/dev/null || echo aurac)
SERVER_ENTRY := cmd/server/main.aura
UNIT_TESTS := tests/order_service_test.aura
INT_TESTS := tests/integration_test.aura
BINARY_OUT := bin/order-service

all: check test build

check:
	@echo "🔍 Verificando tipado y sintaxis en todos los archivos Aura..."
	@$(AURA_BIN) check $(SERVER_ENTRY)
	@$(AURA_BIN) check $(UNIT_TESTS)
	@$(AURA_BIN) check $(INT_TESTS)
	@echo "✓ Verificación completada exitosamente."

build:
	@echo "🔨 Compilando binario nativo del microservicio..."
	@mkdir -p bin
	@$(AURA_BIN) build $(SERVER_ENTRY) -o $(BINARY_OUT)
	@echo "✓ Binario generado en $(BINARY_OUT)"

run:
	@echo "🚀 Ejecutando Microservicio Hexagonal en modo interactivo/servidor..."
	@$(AURA_BIN) run $(SERVER_ENTRY)

test:
	@echo "🧪 Ejecutando Suite de Pruebas Unitarias con Mocks..."
	@$(AURA_BIN) run $(UNIT_TESTS)

test-integration:
	@echo "🔄 Ejecutando Pruebas de Integración End-to-End..."
	@$(AURA_BIN) run $(INT_TESTS)

fmt:
	@echo "🎨 Formateando código fuente de Aura..."
	@$(AURA_BIN) fmt cmd/ internal/ tests/

clean:
	@echo "🧹 Limpiando binarios y temporales..."
	@rm -rf bin/ *.tmp.mjs cmd/server/*.tmp.mjs tests/*.tmp.mjs internal/**/*.tmp.mjs
	@echo "✓ Limpieza completada."

help:
	@echo "Comandos disponibles en el proyecto:"
	@echo "  make run              - Inicia el microservicio y el servidor HTTP"
	@echo "  make test             - Ejecuta las pruebas unitarias aisladas con Mocks"
	@echo "  make test-integration - Ejecuta las pruebas de integración E2E"
	@echo "  make check            - Valida la sintaxis y tipos del código"
	@echo "  make build            - Compila el binario ejecutable"
	@echo "  make clean            - Elimina archivos generados"
