# Gateway Service

AI Gateway Service for D.Coder Platform - Kong-based LLM routing, caching, and compression.

## 🏛️ Architecture

This service follows **Hexagonal Architecture** (Ports & Adapters):

```
src/
├── domain/          # Business logic (core hexagon)
│   ├── models/      # Domain models
│   ├── services/    # Domain services
│   └── ports/       # Interface definitions
├── application/     # Use cases
│   ├── routing/     # LLM routing logic
│   ├── caching/     # Semantic caching
│   └── compression/ # Prompt compression
├── adapters/        # Implementations
│   ├── inbound/     # Kong plugins, HTTP handlers
│   └── outbound/    # External services
└── infrastructure/  # Framework & config
```

## 🚀 Quick Start

### Local Development

```bash
# Start with Docker Compose
docker-compose up -d

# Or use Tilt for hot-reload
tilt up
```

### Configuration

Kong configuration is declarative via `config/kong.yml`:
- Services: Define upstream LLM providers
- Routes: Define API paths
- Plugins: Configure rate limiting, caching, etc.

## 🔌 Features

### Core Capabilities
- **Multi-LLM Routing**: OpenAI, Anthropic, Google Vertex AI, Groq
- **Semantic Caching**: 40-60% token reduction
- **Prompt Compression**: 20-30% size reduction
- **Rate Limiting**: Per-tenant quotas
- **Observability**: Prometheus metrics, distributed tracing

### Kong Plugins Used
- `ai-proxy`: LLM provider routing
- `ai-prompt-template`: Prompt templating
- `ai-prompt-guard`: Security guardrails
- `ai-request-transformer`: Request transformation
- `ai-response-transformer`: Response transformation
- `rate-limiting`: Rate limits with Redis
- `prometheus`: Metrics collection
- `correlation-id`: Request tracing
- `http-log`: Centralized logging

## 📡 API Endpoints

### Proxy Endpoints
- `GET /health` - Health check
- `POST /v1/llm/openai/chat` - OpenAI chat completions
- `POST /v1/llm/anthropic/chat` - Anthropic messages
- `POST /v1/llm/vertex/chat` - Google Vertex AI

### Admin Endpoints
- `GET http://localhost:8001/services` - List services
- `GET http://localhost:8001/routes` - List routes
- `GET http://localhost:8001/plugins` - List plugins
- `GET http://localhost:8001/status` - Gateway status

## 🧪 Testing

```bash
# Run unit tests
pytest tests/unit

# Run integration tests
pytest tests/integration

# Run end-to-end tests
pytest tests/e2e
```

## 🔧 Development

### Adding New LLM Provider

1. Define service in `config/kong.yml`
2. Create route mapping
3. Configure provider-specific plugins
4. Add adapter in `src/adapters/outbound/llm_providers/`

### Custom Kong Plugin Development

1. Create plugin in `plugins/` directory
2. Implement handler in Lua
3. Add schema definition
4. Register in Kong configuration

## 📊 Monitoring

- **Metrics**: http://localhost:8001/metrics (Prometheus format)
- **Health**: http://localhost:8001/status
- **Admin API**: http://localhost:8001

## 🔒 Security

- API key authentication per tenant
- Request/response validation
- Prompt injection prevention
- Rate limiting and quotas
- Audit logging

## 🚢 Deployment

### Docker
```bash
docker build -t dcoder/gateway .
docker run -p 8000:8000 -p 8001:8001 dcoder/gateway
```

### Environment Variables
- `KONG_DATABASE`: Database type (postgres)
- `KONG_PG_HOST`: PostgreSQL host
- `KONG_PG_USER`: PostgreSQL user
- `KONG_PG_PASSWORD`: PostgreSQL password
- `KONG_REDIS_HOST`: Redis host for caching
- `KONG_LOG_LEVEL`: Logging level

## 📚 Documentation

- [Kong Documentation](https://docs.konghq.com/)
- [Kong AI Gateway](https://docs.konghq.com/gateway/latest/ai/)
- [Plugin Development](https://docs.konghq.com/gateway/latest/plugin-development/)
