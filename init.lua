local pending = {}
local EXPIRE = 60

local function msg(player_name, text)
  core.chat_send_player(player_name, text)
end

core.register_chatcommand("tpa", {
  params = "<player>",
  description = "Request to teleport to another player",
  func = function(player1, player2)
    if player2 == "" then
      return false, "Usage: /tpa <player>"
    end
    if player1 == player2 then
      return false, "You can't teleport to yourself."
    end

    if not core.get_player_by_name(player2) then
      return false, "Player '" .. player2 .. "' is not online."
    end

    pending[player2] = { from = player1, time = os.time() }
    msg(player1, "Teleport request sent to " .. player2 .. " (expires in " .. EXPIRE .. "s).")
    msg(player2, player1 .. " wants to teleport to you. Use /tpaccept or /tpdeny.")
    return true
  end,
})

core.register_chatcommand("tpaccept", {
  params = "",
  description = "Accept the last teleport request",
  func = function(player2)
    local req = pending[player2]
    if not req then
      return false, "No pending requests."
    end

    if os.time() - req.time > EXPIRE then
      pending[player2] = nil
      return false, "Request expired."
    end

    local player1 = core.get_player_by_name(req.from)
    local player2_obj = core.get_player_by_name(player2)
    if not player1 then
      pending[player2] = nil
      return false, req.from .. " went offline."
    end
    if not player2_obj then
      pending[player2] = nil
      return false, "You went offline."
    end

    local pos = player2_obj:get_pos()
    player1:set_pos({ x = pos.x, y = pos.y + 1, z = pos.z })

    msg(req.from, "Teleported to " .. player2 .. ".")
    msg(player2, "You accepted " .. req.from .. "'s request.")
    pending[player2] = nil
    return true
  end,
})

core.register_chatcommand("tpdeny", {
  params = "",
  description = "Deny the last teleport request",
  func = function(player2)
    local req = pending[player2]
    if not req then
      return false, "No pending requests."
    end

    msg(req.from, player2 .. " denied your teleport request.")
    msg(player2, "Denied " .. req.from .. ".")
    pending[player2] = nil
    return true
  end,
})

core.register_on_leaveplayer(function(player)
  local name = player:get_player_name()
  for target, info in pairs(pending) do
    if info.from == name then
      pending[target] = nil
    end
  end
end)

core.register_globalstep(function()
  local now = os.time()
  for target, info in pairs(pending) do
    if now - info.time > EXPIRE then
      pending[target] = nil
    end
  end
end)
