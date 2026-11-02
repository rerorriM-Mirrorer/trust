-- A: BattleStations-style local feedback. Keep a plain fallback for minimal
-- runtimes/tests; Windower's chat module supplies the fragment color method.
local M={}
function M.show(section,text)
    pcall(require,'chat')
    if string.color then
        windower.add_to_chat(0,('[Trust]'):color(200)..' '..section:color(167)..' '..('->'):color(200)..' '..tostring(text):color(0))
    elseif addon_system_message then
        addon_system_message('[Trust] '..section..' -> '..tostring(text))
    end
end
return M
