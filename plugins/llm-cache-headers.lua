-- LLM Cache Headers Post-Function
-- Adds X-Cache-Status and X-Cache-Key headers to responses for observability

-- Determine cache status
local cache_status = kong.ctx.shared.cache_hit and "HIT" or "MISS"

-- Add cache status header
kong.response.set_header("X-Cache-Status", cache_status)

-- Add cache key header if it was generated
if kong.ctx.shared.cache_key then
  kong.response.set_header("X-Cache-Key", kong.ctx.shared.cache_key)
end

kong.log.info(string.format("Cache %s for key: %s", cache_status, kong.ctx.shared.cache_key or "N/A"))

