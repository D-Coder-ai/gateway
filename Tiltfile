# Tiltfile for Gateway Service Development

# Load environment variables
load('ext://dotenv', 'dotenv')
dotenv()

# Docker Compose setup
docker_compose('./docker-compose.yml')

# Build Kong with hot-reload for configuration
docker_build(
    'gateway_kong',
    context='.',
    dockerfile='./Dockerfile',
    live_update=[
        sync('./config', '/etc/kong/custom'),
        sync('./plugins', '/usr/local/share/lua/5.1/kong/plugins'),
        run('kong reload', trigger=['./config/kong.yml', './config/routes/*.yml']),
    ]
)

# Port forwards for development
k8s_resource('kong', port_forwards=[
    '8000:8000',  # Proxy
    '8001:8001',  # Admin API
    '8100:8100',  # Status
])

# Local development helpers
local_resource(
    'validate-config',
    'kong config parse ./config/kong.yml',
    deps=['./config/kong.yml']
)

local_resource(
    'list-routes',
    'curl -s http://localhost:8001/routes | jq .',
    labels=['info']
)

local_resource(
    'list-services',
    'curl -s http://localhost:8001/services | jq .',
    labels=['info']
)

local_resource(
    'health-check',
    'curl -s http://localhost:8001/status',
    labels=['monitoring']
)