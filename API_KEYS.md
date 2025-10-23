# LLM Provider API Keys Configuration

## Overview

Kong AI Gateway requires API keys for each LLM provider to authenticate requests. These are BYO (Bring Your Own) credentials for R1.

## Required Environment Variables

The following API keys are required for Kong to authenticate with LLM providers:

- `OPENAI_API_KEY` - OpenAI API key (format: `sk-proj-...`)
- `ANTHROPIC_API_KEY` - Anthropic API key (format: `sk-ant-...`)
- `GOOGLE_API_KEY` - Google Cloud API key (format: `AIza...`)
- `GROQ_API_KEY` - Groq API key (format: `gsk_...`)

## Setup Instructions

### Quick Start

1. **Copy the template file:**
   ```bash
   # Linux/Mac
   cp gateway/env.template gateway/.env
   
   # Windows (PowerShell)
   copy gateway\env.template gateway\.env
   ```

2. **Edit the `.env` file** and fill in your actual API keys

3. **Verify setup:**
   ```bash
   # Source the .env file (Linux/Mac)
   source gateway/.env
   
   # Or load it in PowerShell (Windows)
   Get-Content gateway\.env | ForEach-Object { 
     if ($_ -match '^([^=]+)=(.*)$') { 
       [System.Environment]::SetEnvironmentVariable($matches[1], $matches[2])
     }
   }
   ```

### Manual Setup

Alternatively, create a `.env` file manually in the `gateway/` directory:

```bash
OPENAI_API_KEY=sk-proj-your-key-here
ANTHROPIC_API_KEY=sk-ant-your-key-here
GOOGLE_API_KEY=AIza-your-key-here
GROQ_API_KEY=gsk_your-key-here
```

**Important:** Never commit the `.env` file to version control (it's already in `.gitignore`)

## Key Sources

| Provider | Key Format | Get Your Key |
|----------|-----------|--------------|
| OpenAI | `sk-proj-...` | https://platform.openai.com/api-keys |
| Anthropic | `sk-ant-...` | https://console.anthropic.com/settings/keys |
| Google | `AIza...` | https://console.cloud.google.com/apis/credentials |
| Groq | `gsk_...` | https://console.groq.com/keys |

## How Keys are Used

Kong's `request-transformer` plugin injects these keys into the appropriate headers:

- **OpenAI**: `Authorization: Bearer $(OPENAI_API_KEY)`
- **Anthropic**: `x-api-key: $(ANTHROPIC_API_KEY)` + `anthropic-version: 2023-06-01`
- **Google**: `x-goog-api-key: $(GOOGLE_API_KEY)`
- **Groq**: `Authorization: Bearer $(GROQ_API_KEY)`

## Testing Without Keys

If you don't provide a key, Kong will substitute an empty string. Provider APIs will return `401 Unauthorized` errors.

## Security Notes

- Keys are environment variables in R1 (MVP approach)
- R2+ will use Vault/KMS with `secretRef` pattern
- Keys are redacted from Kong access logs
- Rotate keys immediately if exposed

## Troubleshooting

**401 Errors from Provider APIs:**
- Verify the key is set in `.env`
- Check the key format matches the provider's pattern
- Test the key directly against the provider's API

**Keys Visible in Logs:**
- Kong should redact `Authorization` and `x-api-key` headers
- Report as a security issue if keys appear in logs

