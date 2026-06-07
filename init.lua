local pending = {}
local EXPIRE = 60

local function msg(player, text)
  core.chat_send_player(player, text)
end

core.register_chatcommand("tpa", {
  params = "<player>",
  description = "Ask to teleport to someone",
  func = function(me, target)
    if target == "" then return false, "Usage: /tpa <player>" end
    if me == target then return false, "You already are there." end
    if not core.get_player_by_name(target) then
      return false, "Player '"..target.."' not online."
    end

    pending[target] = { from = me, t = os.time() }
    msg(me, "Request sent to "..target.." (expires in "..EXPIRE.."s).")
    msg(target, me.." wants to teleport to you. /tpaccept or /tpdeny")
    return true
  end,
})

core.register_chatcommand("tpaccept", {
  params = "",
  description = "Accept the last teleport request",
  func = function(me)
    local req = pending[me]
    if not req then return false, "No pending requests." end
    if os.time() - req.t > EXPIRE then pending[me] = nil; return false, "Request expired." end

    local from = core.get_player_by_name(req.from)
    local to = core.get_player_by_name(me)
    if not from then pending[me] = nil; return false, req.from.." went offline." end
    if not to then pending[me] = nil; return false, "You went offline." end

    local p = to:get_pos()
    from:set_pos({ x = p.x, y = p.y + 1, z = p.z })
    msg(req.from, "Teleported to "..me..".")
    msg(me, "You accepted "..req.from..".")
    pending[me] = nil
    return true
  end,
})

core.register_chatcommand("tpdeny", {
  params = "",
  description = "Deny the last teleport request",
  func = function(me)
    local req = pending[me]
    if not req then return false, "No pending requests." end
    msg(req.from, me.." denied your request.")
    msg(me, "Denied "..req.from..".")
    pending[me] = nil
    return true
  end,
})

core.register_on_leaveplayer(function(player)
  local n = player:get_player_name()
  for t, v in pairs(pending) do
    if v.from == n then pending[t] = nil end
  end
end)

core.register_globalstep(function()
  local now = os.time()
  for t, v in pairs(pending) do
    if now - v.t > EXPIRE then pending[t] = nil end
  end
end)
