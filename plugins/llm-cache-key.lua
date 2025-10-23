-- LLM Semantic Cache Key Generator
-- Provider-aware cache key generation for OpenAI, Anthropic, Google, and Groq
-- Generates format: llm:{tenantId}:{provider}:{model}:{hash}

local cjson = require "cjson.safe"
local resty_sha256 = require "resty.sha256"
local str = require "resty.string"

-- Extract provider and model from route name (format: llm.{provider}.{model})
local function extract_route_info()
  local route = kong.router.get_route()
  if not route or not route.name then
    return nil, nil
  end
  
  -- Route name format: llm.openai.gpt-5
  local parts = {}
  for part in string.gmatch(route.name, "[^%.]+") do
    table.insert(parts, part)
  end
  
  if #parts >= 3 and parts[1] == "llm" then
    return parts[2], table.concat(parts, ".", 3) -- provider, model
  end
  
  return nil, nil
end

-- Normalize messages/contents to string for consistent hashing
local function normalize_messages(messages)
  if type(messages) ~= "table" then
    return tostring(messages or "")
  end
  
  local normalized = {}
  for i, msg in ipairs(messages) do
    if type(msg) == "table" then
      -- For OpenAI/Anthropic format: {role: "user", content: "..."}
      if msg.content then
        table.insert(normalized, tostring(msg.content))
      -- For Google format: {parts: [{text: "..."}]}
      elseif msg.parts then
        for _, part in ipairs(msg.parts) do
          if part.text then
            table.insert(normalized, tostring(part.text))
          end
        end
      end
    end
  end
  
  -- Collapse whitespace and join
  local text = table.concat(normalized, " ")
  text = text:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
  return text
end

-- Parse request body based on provider
local function parse_request_body(provider, body)
  if not body then
    return nil, nil, nil, nil
  end
  
  local messages, temperature, top_p, max_tokens
  
  if provider == "openai" or provider == "groq" then
    -- OpenAI/Groq format: {messages: [...], temperature, top_p, max_tokens}
    messages = body.messages
    temperature = body.temperature
    top_p = body.top_p
    max_tokens = body.max_tokens
    
  elseif provider == "anthropic" then
    -- Anthropic format: {messages: [...], temperature, max_tokens}
    messages = body.messages
    temperature = body.temperature
    max_tokens = body.max_tokens
    
  elseif provider == "google" then
    -- Google format: {contents: [...], generationConfig: {...}}
    messages = body.contents
    local config = body.generationConfig or {}
    temperature = config.temperature
    top_p = config.topP
    max_tokens = config.maxOutputTokens
  end
  
  return messages, temperature, top_p, max_tokens
end

-- Generate SHA256 hash
local function generate_hash(input_string)
  local sha256 = resty_sha256:new()
  if not sha256 then
    kong.log.err("Failed to create SHA256 object")
    return nil
  end
  
  local ok = sha256:update(input_string)
  if not ok then
    kong.log.err("Failed to update SHA256 hash")
    return nil
  end
  
  local digest = sha256:final()
  return str.to_hex(digest):sub(1, 16) -- Use first 16 chars of hash
end

-- Main cache key generation function
local function generate_cache_key()
  -- Get tenant ID from header, default to "default"
  local tenant_id = kong.request.get_header("X-Tenant-Id") or "default"
  
  -- Extract provider and model from route name
  local provider, model = extract_route_info()
  if not provider or not model then
    kong.log.warn("Could not extract provider/model from route name")
    return nil
  end
  
  -- Parse request body
  local body_raw = kong.request.get_raw_body()
  if not body_raw then
    kong.log.warn("No request body found")
    return nil
  end
  
  local body, err = cjson.decode(body_raw)
  if not body then
    kong.log.err("Failed to parse request body: ", err)
    return nil
  end
  
  -- Parse provider-specific parameters
  local messages, temperature, top_p, max_tokens = parse_request_body(provider, body)
  
  -- Normalize messages to consistent string
  local normalized_prompt = normalize_messages(messages)
  
  -- Build hash input with all cache-relevant parameters
  -- Format: tenantId||provider||model||prompt||temperature||top_p||max_tokens
  local hash_parts = {
    tenant_id,
    provider,
    model,
    normalized_prompt,
    tostring(temperature or ""),
    tostring(top_p or ""),
    tostring(max_tokens or "")
  }
  
  local hash_input = table.concat(hash_parts, "||")
  
  -- Generate hash
  local hash = generate_hash(hash_input)
  if not hash then
    kong.log.err("Failed to generate hash for cache key")
    return nil
  end
  
  -- Format: llm:{tenantId}:{provider}:{model}:{hash}
  local cache_key = string.format("llm:%s:%s:%s:%s", tenant_id, provider, model, hash)
  
  kong.log.debug("Generated cache key: ", cache_key)
  return cache_key
end

-- Execute and set cache key in kong context
local cache_key = generate_cache_key()
if cache_key then
  kong.ctx.shared.cache_key = cache_key
  -- Also set in response context for debugging
  kong.ctx.shared.cache_key_generated = true
else
  kong.log.warn("Failed to generate cache key, caching will be skipped")
  kong.ctx.shared.cache_key_generated = false
end

