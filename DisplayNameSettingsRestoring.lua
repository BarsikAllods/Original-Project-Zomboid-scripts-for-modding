local DisplayNameSettingsRestored = {}

local function trim(s)
  if not s then return "" end
  return tostring(s):gsub("^%s+", ""):gsub("%s+$", "")
end

function DisplayNameSettingsRestored:getMode()
  local serverOptions = getServerOptions()
  if not serverOptions then
    return "username"
  end

  local showFirstAndLastName = serverOptions:getBoolean("ShowFirstAndLastName")
  local showUserName = serverOptions:getBoolean("DisplayUserName")

  if showFirstAndLastName then
    return "character"
  end

  if showUserName then
    return "username"
  end

  return "none"
end

function DisplayNameSettingsRestored:getCharacterName(player)
  local descriptor = player and player:getDescriptor()
  if not descriptor then
    return ""
  end

  local forename = trim(descriptor:getForename())
  local surname = trim(descriptor:getSurname())

  if forename ~= "" and surname ~= "" then
    return forename .. " " .. surname
  end

  if forename ~= "" then
    return forename
  end

  if surname ~= "" then
    return surname
  end

  return ""
end

function DisplayNameSettingsRestored:getTargetDisplayName(player, mode)
  if mode == "character" then
    local fullName = self:getCharacterName(player)
    if fullName ~= "" then
      return fullName
    end
  end

  if mode == "none" then
    return ""
  end

  return trim(player and player:getUsername())
end

function DisplayNameSettingsRestored:findPlayerByName(name)
  local targetName = trim(name)
  if targetName == "" then
    return nil
  end

  if getPlayerFromUsername then
    local byUsername = getPlayerFromUsername(targetName)
    if byUsername then
      return byUsername
    end
  end

  local onlinePlayers = getOnlinePlayers()
  if not onlinePlayers then
    return nil
  end

  for i = 0, onlinePlayers:size() - 1 do
    local player = onlinePlayers:get(i)
    if player then
      local username = trim(player:getUsername())
      local displayName = trim(player:getDisplayName())
      if username == targetName or displayName == targetName then
        return player
      end
    end
  end

  return nil
end

function DisplayNameSettingsRestored:applyToChatMessage(message)
  if not message or not message.getAuthor or not message.setAuthor then
    return
  end

  local mode = self:getMode()
  if mode ~= "character" then
    return
  end

  local author = trim(message:getAuthor())
  if author == "" then
    return
  end

  local player = self:findPlayerByName(author)
  if not player then
    return
  end

  local targetAuthor = self:getCharacterName(player)
  if targetAuthor == "" or targetAuthor == author then
    return
  end

  message:setAuthor(targetAuthor)
end

function DisplayNameSettingsRestored:applyToPlayer(player, mode)
  if not player then
    return
  end

  local targetDisplayName = self:getTargetDisplayName(player, mode)
  local currentDisplayName = trim(player:getDisplayName())

  if targetDisplayName ~= currentDisplayName then
    player:setDisplayName(targetDisplayName)
  end
end

function DisplayNameSettingsRestored:apply()
  if not isClient() then
    return
  end

  local mode = self:getMode()

  local localPlayer = getPlayer()
  if localPlayer then
    self:applyToPlayer(localPlayer, mode)
  end

  local onlinePlayers = getOnlinePlayers()
  if not onlinePlayers then
    return
  end

  for i = 0, onlinePlayers:size() - 1 do
    self:applyToPlayer(onlinePlayers:get(i), mode)
  end
end

if Events.OnConnected then
    Events.OnConnected.Add(function()
        DisplayNameSettingsRestored:apply()
    end)
end

if Events.OnCreatePlayer then
  Events.OnCreatePlayer.Add(function()
    DisplayNameSettingsRestored:apply()
  end)
end

if Events.OnScoreboardUpdate then
  Events.OnScoreboardUpdate.Add(function()
    DisplayNameSettingsRestored:apply()
  end)
end

if Events.OnAddMessage then
  Events.OnAddMessage.Add(function(message)
    DisplayNameSettingsRestored:applyToChatMessage(message)
  end)
end

if Events.EveryTenMinutes then
  Events.EveryTenMinutes.Add(function()
    DisplayNameSettingsRestored:apply()
  end)
end