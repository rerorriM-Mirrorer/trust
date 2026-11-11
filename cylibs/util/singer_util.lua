-- Song conditions share the one active Singer, whether BRD is main or sub.
local M = {}
function M.get_singer()
    local trusts = player and player.trust
    if not trusts then return nil end
    for _, key in ipairs({'main_job', 'sub_job'}) do
        local trust = trusts[key]
        local singer = trust and trust:role_with_type('singer')
        if singer and singer.song_tracker then return singer end
    end
end
return M
