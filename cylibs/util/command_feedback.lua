-- A: narrowly scoped success-feedback suppression for automated commands.
-- Nothing is filtered by text or delayed by a timer. Errors still use their
-- ordinary path, and nested callbacks restore the prior scope even on failure.
local feedback = {}
local depth = 0

function feedback.is_quiet()
    return depth > 0
end

function feedback.run(quiet, callback)
    -- Ordinary commands retain their original call path (including any
    -- coroutine behavior); only synchronous quiet follow/assist are scoped.
    if not quiet and depth == 0 then return callback() end
    local previous = depth
    if quiet then depth = depth + 1 end
    local ok, success, message = pcall(callback)
    depth = previous
    if not ok then error(success, 0) end
    return success, message
end

return feedback
