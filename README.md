# Microservicio de Facturación y Gestión de Órdenes en Aura Lang
### *Arquitectura Hexagonal (Ports & Adapters) con Estilo de Programación Idiomático Golang*

Este proyecto implementa un microservicio completo y robusto para la **Gestión, Cobro y Despacho de Órdenes**, diseñado siguiendo estrictamente los principios de la **Arquitectura Hexagonal (Puertos y Adaptadores)** de Alistair Cockburn y el modelo idiomático de programación de **Golang** en el lenguaje **Aura** (`aurac`).

---

## 🏛️ Visión General de la Arquitectura Hexagonal

La arquitectura desacopla por completo la lógica de negocio central (el núcleo del hexágono) de cualquier detalle tecnológico o de infraestructura externa (base de datos, pasarelas de pago, brokers de mensajería, controladores HTTP).

```
                            ┌─────────────────────────────────────────┐
                            │            ADAPTADORES INBOUND          │
                            │             (Driving / Primarios)       │
                            │                                         │
                            │  [HTTP REST Handler]   [CLI Runner]     │
                            └────────────────────┬────────────────────┘
                                                 │
                                                 ▼ (Invoca)
┌────────────────────────────────────────────────┼───────────────────────────────────────────────┐
│ NÚCLEO DEL HEXÁGONO (Core Domain & Ports)      │                                               │
│                                                │                                               │
│      ┌─────────────────────────────────────────┴───────────────────────────┐                   │
│      │               PUERTOS PRIMARIOS / INBOUND (Interfaces)              │                   │
│      │               • OrderServicePort (Casos de Uso)                     │                   │
│      └─────────────────────────────────────────┬───────────────────────────┘                   │
│                                                │                                               │
│                                                ▼                                               │
│      ┌─────────────────────────────────────────────────────────────────────┐                   │
│      │               CASO DE USO / SERVICIO DE APLICACIÓN                  │                   │
│      │               • OrderService (Implementa OrderServicePort)          │                   │
│      │               • Constructor DI ("Acepta interfaces, retorna struct")│                   │
│      │               • Coordinación y Transacciones de Compensación        │                   │
│      └─────────────────────────────────────────┬───────────────────────────┘                   │
│                                                │                                               │
│                                                ▼                                               │
│      ┌─────────────────────────────────────────────────────────────────────┐                   │
│      │               DOMINIO PURO (Entities & Value Objects)               │                   │
│      │               • Order (Agregado Raíz)  • Customer  • OrderItem      │                   │
│      │               • DomainEvent            • Invariantes & Errores      │                   │
│      └─────────────────────────────────────────┬───────────────────────────┘                   │
│                                                │                                               │
│      ┌─────────────────────────────────────────┴───────────────────────────┐                   │
│      │               PUERTOS SECUNDARIOS / OUTBOUND (Interfaces)           │                   │
│      │  • OrderRepositoryPort        • PaymentGatewayPort                  │                   │
│      │  • EventPublisherPort         • NotificationPort                    │                   │
│      │  • MetricsCollectorPort                                             │                   │
│      └─────────────────────────────────────────┬───────────────────────────┘                   │
└────────────────────────────────────────────────┼───────────────────────────────────────────────┘
                                                 │
                                                 ▼ (Implementan)
                            ┌────────────────────┴────────────────────┐
                            │            ADAPTADORES OUTBOUND         │
                            │             (Driven / Secundarios)      │
                            │                                         │
                            │  • InMemoryOrderRepository (Mutex Safe) │
                            │  • StripePaymentGateway (Pagos/Refunds) │
                            │  • AsyncEventBus (Pub/Sub & Auditoría)  │
                            │  • EmailNotifier (Transaccional)        │
                            │  • PrometheusMetrics (Telemetría)       │
                            └─────────────────────────────────────────┘
```

---

## 🦫 Estilo de Programación Idiomático Golang en Aura

El diseño del código refleja los patrones y modismos de Go:

1. **"Acepta interfaces, retorna structs"**:
   - Las capas de aplicación y los servicios nunca dependen de structs concretos; sus constructores reciben puertos (interfaces).
   - Constructores nombrados `New...` (`NewOrderService`, `NewInMemoryOrderRepository`, `NewOrderHttpHandler`).
2. **Duck Typing Estructural**:
   - Las interfaces en Aura se satisfacen implícitamente por la estructura de los métodos implementados, sin necesidad de palabras clave como `implements`.
3. **Manejo Explícito de Errores con `Result<T, String>`**:
   - Se devuelven tuplas lógicas `Ok(valor)` o `Err(mensaje)`, evitando el uso de excepciones no controladas.
4. **Métodos con Receiver**:
   - Definición de métodos asociados a estructuras usando sintaxis de receptor: `fn (s: OrderService) CreateOrder(...)`.
5. **Concurrencia Segura y `defer`**:
   - Uso de `Mutex` (`mu.lock()`, `defer mu.unlock()`) para sincronización en adaptadores de persistencia y telemetría.
6. **Slices y Colecciones Dinámicas**:
   - Slices nativos (`[]OrderItem`, `append()`, `len()`).

---

## 📂 Estructura del Proyecto

```
hexadecimal/
├── aura.mod                                      # Definición del módulo Aura (aurac mod)
├── Makefile                                      # Automatización de tareas (build, test, run)
├── run.sh                                        # Script de inicio rápido en una línea
├── .env.example                                  # Variables de configuración de ambiente
├── .gitignore                                    # Exclusiones de control de versiones
├── cmd/
│   └── server/
│       └── main.aura                             # Composition Root (Inyección de Dependencias)
├── internal/
│   ├── core/
│   │   ├── domain/                               # Capa de Dominio Puro
│   │   │   ├── order.aura                        # Agregado Order, OrderItem, Customer, FSM
│   │   │   ├── events.aura                       # Domain Events & Constants
│   │   │   └── errors.aura                       # Errores estándar y constructores de dominio
│   │   ├── ports/                                # Capa de Puertos (Interfaces)
│   │   │   ├── inbound.aura                      # Puerto Primario: OrderServicePort & DTOs
│   │   │   └── outbound.aura                     # Puertos Secundarios (Repo, Payment, PubSub, Notifier, Metrics)
│   │   └── services/                             # Capa de Casos de Uso
│   │       └── order_service.aura                # Orquestador del Dominio (Pure DI)
│   └── adapters/
│       ├── inbound/                              # Adaptadores Primarios (Driving)
│       │   ├── http/
│       │   │   ├── handler.aura                  # Controladores REST HTTP
│       │   │   ├── router.aura                   # Registro de rutas en ServeMux
│       │   │   └── middleware.aura               # Logging, CORS y Request Buffering
│       │   └── cli/
│       │       └── cli_runner.aura               # Ejecutor interactivo por línea de comandos
│       └── outbound/                             # Adaptadores Secundarios (Driven)
│           ├── persistence/
│           │   └── inmemory_repo.aura            # Repositorio en memoria thread-safe
│           ├── payment/
│           │   └── stripe_gateway.aura           # Pasarela de pagos Stripe (Cargos/Reembolsos)
│           ├── messaging/
│           │   └── async_event_bus.aura          # Publicador y Store de eventos de dominio
│           ├── notification/
│           │   └── email_notifier.aura           # Notificador transaccional por Email
│           └── telemetry/
│               └── prometheus_metrics.aura       # Colector y exportador de métricas Prometheus
└── tests/
    ├── order_service_test.aura                   # Pruebas Unitarias Aisladas con Mocks
    └── integration_test.aura                     # Pruebas de Integración End-to-End
```

---

## 🚀 Guía de Ejecución

### Requisitos
- Compilador **Aura Lang** (`aurac`) instalado en el PATH o en `~/.cargo/bin/aurac`.

### 1. Ejecución con Makefile
```bash
# Validar sintaxis y tipos
make check

# Ejecutar pruebas unitarias (con Mocks aislados)
make test

# Ejecutar pruebas de integración E2E
make test-integration

# Iniciar el servidor del microservicio
make run
```

### 2. Ejecución con el Script `run.sh`
```bash
./run.sh
```

---

## 📡 API REST - Referencia de Endpoints

El microservicio expone una API REST completa en el puerto configurado (por defecto `8080`):

### 1. Health Check
```bash
curl -s http://localhost:8080/health | jq
```
**Respuesta (200 OK):**
```json
{
  "status": "UP",
  "service": "order-billing-hexagonal-microservice",
  "architecture": "Hexagonal (Ports & Adapters)",
  "style": "Golang Idiomatic Model",
  "language": "Aura Lang Native",
  "version": "1.0.0"
}
```

### 2. Métricas del Microservicio
```bash
curl -s http://localhost:8080/metrics | jq
```
**Respuesta (200 OK):**
```json
{
  "totalOrders": 2,
  "pendingOrders": 0,
  "confirmedOrders": 0,
  "paidOrders": 0,
  "shippedOrders": 1,
  "cancelledOrders": 1,
  "totalRevenue": 6097
}
```

### 3. Listar Órdenes
```bash
curl -s http://localhost:8080/api/v1/orders | jq
```

### 4. Crear una Nueva Orden
```bash
curl -s -X POST http://localhost:8080/api/v1/orders \
  -H "Content-Type: application/json" \
  -d '{
    "customerId": "cust-500",
    "customerName": "Linus Torvalds",
    "customerEmail": "torvalds@kernel.org",
    "shippingAddress": "Portland, OR, USA",
    "currency": "USD",
    "items": [
      {
        "productId": "thinkpad-x1",
        "title": "ThinkPad X1 Carbon Gen 12",
        "quantity": 1,
        "unitPrice": 1850.0
      },
      {
        "productId": "yubikey-5c",
        "title": "YubiKey 5C NFC FIPS",
        "quantity": 2,
        "unitPrice": 75.0
      }
    ]
  }' | jq
```

### 5. Confirmar Orden
```bash
curl -s -X POST http://localhost:8080/api/v1/orders/ORD-1003/confirm | jq
```

### 6. Pagar Orden (Integración Pasarela)
```bash
curl -s -X POST http://localhost:8080/api/v1/orders/ORD-1003/pay \
  -H "Content-Type: application/json" \
  -d '{"paymentToken": "tok_visa_signature"}' | jq
```

### 7. Despachar Orden
```bash
curl -s -X POST http://localhost:8080/api/v1/orders/ORD-1003/ship \
  -H "Content-Type: application/json" \
  -d '{"trackingNumber": "DHL-EXP-440192"}' | jq
```

### 8. Cancelar Orden (con Reembolso Automático si fue pagada)
```bash
curl -s -X POST http://localhost:8080/api/v1/orders/ORD-1003/cancel \
  -H "Content-Type: application/json" \
  -d '{"reason": "Cancelación solicitada por cliente"}' | jq
```

---

## 🧪 Pruebas Automatizadas

El proyecto incluye dos suites de pruebas completas:

1. **`tests/order_service_test.aura` (Pruebas Unitarias)**:
   - Implementa un `MockOrderRepo` en memoria.
   - Evalúa cálculo exacto de subtotales y totales.
   - Verifica rechazo de órdenes inválidas (lista de items vacía).
   - Valida la máquina de estados y transiciones legales (`Pending` -> `Confirmed` -> `Paid` -> `Shipped`).
   - Verifica el bloqueo de transiciones ilegales (`Shipped` -> `Cancelled`).
   - Simula tarjetas declinadas en la pasarela de pagos.

2. **`tests/integration_test.aura` (Pruebas de Integración)**:
   - Ensambla todos los adaptadores reales.
   - Prueba inserción masiva y paginación.
   - Verifica la auditoría de eventos en el `AsyncEventBus`.
   - Verifica los contadores del adaptador de `EmailNotifier`.
   - Genera y valida la salida en formato oficial de Prometheus.

---

## 🛡️ Licencia y Créditos
- Desarrollado en el lenguaje **Aura** (`aurac`).
- Arquitectura Hexagonal y Principios de Diseño basados en el ecosistema Go.
