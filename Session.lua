-- Aktive Session: vom Login bis zum Logout.
-- /reload und kurze Unterbrechungen setzen die Session fort. Beim nächsten echten Login
-- wird die alte Session in die Session-Historie verschoben und eine neue beginnt.
local _, ns = ...

local Session = {}
ns.Session = Session

local RESUME_GAP_SECONDS = 300   -- kürzere Pausen (z.B. /reload, Disconnect) gehören zur selben Session
local MIN_ARCHIVED_SECONDS = 60  -- kürzere Sessions werden nicht archiviert
local MAX_ARCHIVED_SESSIONS = 200

local loginTime  -- GetTime() beim Login; Zeit seitdem kommt zu currentSession.seconds dazu

local function current()
  return ns.character.currentSession
end

function Session.GetSeconds()
  return current().seconds + (GetTime() - loginTime)
end

-- Historien-Eintrag aus einer beendeten Session (Form wie in History.lua beschrieben)
function Session.ToRecord(session)
  return {
    startedAt = session.startedAt,
    endedAt = session.lastSeen,
    seconds = session.seconds,
    startLevel = session.startLevel,
    endLevel = session.endLevel or session.startLevel,
    xp = session.counters.xpGained or 0,
    counters = session.counters,
  }
end

local function archive(session)
  if session.seconds < MIN_ARCHIVED_SECONDS then return end
  local history = ns.character.sessionHistory
  table.insert(history, Session.ToRecord(session))
  while #history > MAX_ARCHIVED_SESSIONS do
    table.remove(history, 1)
  end
end

local function startNew()
  ns.character.currentSession = {
    startedAt = time(),
    seconds = 0,
    startLevel = ns.level,
    endLevel = ns.level,
    counters = ns.Database.NewCounters(),
  }
end

local function canResume(session)
  return session.lastSeen ~= nil and time() - session.lastSeen <= RESUME_GAP_SECONDS
end

ns.OnLogin(function()
  local session = current()
  if not session.startedAt then
    startNew()
  elseif not canResume(session) then
    archive(session)
    startNew()
  end
  loginTime = GetTime()
end)

ns.OnLevelStarted(function(newLevel)
  current().endLevel = newLevel
end)

ns.OnLogout(function()
  local session = current()
  session.seconds = Session.GetSeconds()
  session.lastSeen = time()
  session.endLevel = ns.level
  loginTime = GetTime()  -- falls nach dem Logout noch gelesen wird, nicht doppelt zählen
end)
