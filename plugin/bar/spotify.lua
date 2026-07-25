local wez = require "wezterm"
local utilities = require "bar.utilities"

---@private
---@class bar.spotify
local M = {}

local last_update = 0
local stored_playback = ""

local function apply_format_rules(text, rules)
  for _, rule in ipairs(rules) do
    local pattern, replacement = rule[1], rule[2]
    text = text:gsub(pattern, replacement)
  end
  return text
end

---format spotify playback, to handle max_width nicely
---@param pb string
---@param max_width integer
---@return string
local format_playback = function(pb, max_width, gsubs)
  -- Apply user-defined gsubs
  pb = apply_format_rules(pb, gsubs)

  if #pb <= max_width then
    return pb
  end

  -- split on " - "
  local artist, track = pb:match "^(.-) %- (.+)$"
  artist = artist or ""
  track = track or ""
  -- get artist before first ","
  local pb_main_artist = artist:match "([^,]+)" .. " - " .. track
  if #pb_main_artist <= max_width then
    return pb_main_artist
  end

  -- fallback, return track name (trimmed to max width)
  return track:sub(1, max_width)
end

---gets the currently playing song from spotify
---@param max_width integer
---@param throttle integer
---@return string
M.get_currently_playing = function(max_width, throttle, command, gsubs)
  if utilities._wait(throttle, last_update) then
    return stored_playback
  end

  -- Fallback to the command for spotatui if unspecified.
  if not command or command == "" then
    command = {"spotatui", "playback", "--format", "\"%a - %t\""}
  end

  -- You get the idea.
  if not gsubs or gsubs == {} then
    gsubs = {"^Logging to: [^\n]+%s*", ""}
  end
  
  -- fetch playback using spotify-tui
  local success, pb, stderr = wez.run_child_process(command)
  if not success then
    wez.log_error(stderr)
    return ""
  end

  local res = format_playback(utilities._trim(pb) or "", max_width, gsubs)
  stored_playback = res
  last_update = os.time()

  return res
end

return M
