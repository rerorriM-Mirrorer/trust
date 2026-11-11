-- Shared chat presentation. Command handlers retain their plain return values
-- so quiet calls and callers inspecting failures keep the same control flow.
local M = {}
local function color(text, value)
    return string.color and tostring(text):color(value) or tostring(text)
end
local function value_text(text)
    local body, state = text:match('^(.-)%s+(ON)$')
    if not state then body, state = text:match('^(.-)%s+(OFF)$') end
    if state then return color(body..' ',0)..color(state,state=='ON' and 158 or 167) end
    if text=='ON' or text=='On' or text=='Active' then return color(text,158) end
    if text=='OFF' or text=='Off' or text=='Paused' then return color(text,167) end
    return color(text,0)
end
function M.format(text, failed)
    text = tostring(text or (failed and 'Command failed' or ''))
    if failed then return color(text,167) end
    -- Existing fragment-formatted messages retain their original colors.
    if text:find('[\30\31]') then return text end
    local label, value = text:match('^([^:\n]+):%s*(.*)$')
    if label then return color(label..': ',167)..value_text(value) end
    local state, detail = text:match('^(Active) %- (.*)$')
    if not state then state, detail = text:match('^(Paused) %- (.*)$') end
    if state then return value_text(state)..color(' - '..detail,0) end
    return value_text(text)
end
function M.show(text, failed)
    pcall(require,'chat')
    windower.add_to_chat(0,color('[Trust] ',200)..M.format(text,failed))
end
return M
