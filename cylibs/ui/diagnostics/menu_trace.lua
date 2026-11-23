-- A: Trust menu trace, modeled on xivcrossbar's //xb rendertrace.
-- One file holds input (keyboard + controller), frames, focus, cursor,
-- scrolling and every Windower image Trust touches, in order.
-- Off by default: no hooks are installed until //trust menutrace on.
-- Events stay in a memory ring; the disk is written only on save.
local M = {
    enabled = false,
    capacity = 30000,  -- lines kept (oldest overwritten)
    gap = 0.05,        -- seconds; a frame slower than this logs frame-gap
}

local clock = function() return require('socket').gettime() end
local events, head, count, dropped, frame = {}, 1, 0, 0, 0
local started, previous_frame, context = 0, nil, nil
local counters, max_gap = {}, 0
local ids, next_id = setmetatable({}, { __mode = 'k' }), 0
local key_event, image_hooks = nil, nil

function M.set_clock(fn) clock = fn end

local function clean(value)
    local s = tostring(value == nil and '<nil>' or value)
    return (s:gsub('[\r\n\t|]', ' ')):sub(1, 200)
end

local function append(kind, id, values)
    local line = string.format('%.6f\t%d\t%s\t%s\t%s', clock(), frame, kind, id or '-', values or '')
    local index = (head + count - 1) % M.capacity + 1
    if count == M.capacity then
        index = head; head = head % M.capacity + 1; dropped = dropped + 1
    else
        count = count + 1
    end
    events[index] = line
    counters[kind] = (counters[kind] or 0) + 1
end

local function join(...)
    local values = {}
    for i = 1, select('#', ...) do values[i] = clean(select(i, ...)) end
    return table.concat(values, '|')
end

function M.event(kind, ...)
    if not M.enabled then return end
    append(kind, nil, join(...))
end

-- Stable small id per object (views, images) for the life of the session.
function M.id(object, kind)
    local info = ids[object]
    if not info then
        next_id = next_id + 1
        info = { id = (kind or 'obj')..next_id, last = {} }
        ids[object] = info
    end
    return info
end

-- Log only when a value changes for this object (Trust re-lays-out every image
-- every frame, so unchanged repeats would flood the ring).
function M.call(object, kind, ...)
    if not M.enabled then return end
    local info = M.id(object)
    local value = join(...)
    counters['calls.'..kind] = (counters['calls.'..kind] or 0) + 1
    if info.last[kind] == value then return end
    info.last[kind] = value
    append(kind, info.id, value)
end

function M.frame(now)
    if not M.enabled then return end
    now = now or clock()
    frame = frame + 1
    if previous_frame then
        local gap = now - previous_frame
        if gap > max_gap then max_gap = gap end
        if gap > M.gap then M.event('frame-gap', string.format('%.4f', gap)) end
    end
    previous_frame = now
end

function M.context(...)
    if not M.enabled then return end
    local value = join(...)
    if context ~= value then context = value; append('context', nil, value) end
end

-- Short creator chain for a new image: the nearest Trust source lines.
local function creator()
    if not debug or not debug.getinfo then return '?' end
    local parts = {}
    for level = 3, 9 do
        local info = debug.getinfo(level, 'Sl')
        if not info then break end
        local src = (info.short_src or '?'):gsub('^.*[/\\]addons[/\\]Trust[/\\]', '')
        if not src:find('menu_trace', 1, true) and not src:find('images', 1, true) then
            parts[#parts + 1] = src..':'..tostring(info.currentline)
            if #parts == 3 then break end
        end
    end
    return table.concat(parts, ' < ')
end

-- Wrap the Windower images library while tracing. A visible image with no
-- texture and no colour set is drawn as a plain box: flagged as UNTEXTURED.
local IMAGE_METHODS = { 'visible', 'show', 'hide', 'path', 'pos', 'size', 'alpha', 'color', 'destroy' }

local function install_image_hooks(images)
    if image_hooks or type(images) ~= 'table' or type(images.new) ~= 'function' then return false end
    image_hooks = { lib = images, original = {} }
    local original = image_hooks.original
    original.new = images.new
    images.new = function(...)
        local image = original.new(...)
        if M.enabled then
            local info = M.id(image, 'img')
            info.state = { path = '', visible = false, colored = false }
            append('img.new', info.id, creator())
        end
        return image
    end
    for _, name in ipairs(IMAGE_METHODS) do
        local fn = images[name]
        if type(fn) == 'function' then
            original[name] = fn
            images[name] = function(image, ...)
                local n = select('#', ...)
                if M.enabled and (n > 0 or name == 'show' or name == 'hide' or name == 'destroy') then
                    local info = M.id(image, 'img')
                    local state = info.state or { path = '?', visible = '?', colored = false }
                    info.state = state
                    if name == 'show' or name == 'hide' or name == 'visible' then
                        local visible = name == 'show' or (name == 'visible' and (...) and true or false)
                        if visible ~= state.visible then
                            state.visible = visible
                            local flag = (visible and state.path == '' and not state.colored) and 'UNTEXTURED' or ''
                            append(visible and 'img.show' or 'img.hide', info.id, join(state.path, flag))
                        end
                    elseif name == 'path' then
                        state.path = tostring((...) or '')
                        M.call(image, 'img.path', state.path)
                    elseif name == 'color' then
                        state.colored = true
                        M.call(image, 'img.color', ...)
                    elseif name == 'destroy' then
                        append('img.destroy', info.id, state.path)
                    else
                        M.call(image, 'img.'..name, ...)
                    end
                end
                return fn(image, ...)
            end
        end
    end
    return true
end

local function remove_image_hooks()
    if not image_hooks then return end
    for name, fn in pairs(image_hooks.original) do image_hooks.lib[name] = fn end
    image_hooks = nil
end

-- options: images (library table), register/unregister (Windower events), key_name(dik)
function M.start(options)
    if M.enabled then return false end
    options = options or {}
    events, head, count, dropped, frame = {}, 1, 0, 0, 0
    counters, max_gap, context, previous_frame = {}, 0, nil, nil
    started = clock()
    M.enabled = true
    M.hooks = install_image_hooks(options.images) and 'images' or 'no image hooks'
    if options.register then
        key_event = options.register('keyboard', function(key, pressed, flags, blocked)
            M.event('key', string.format('0x%02X', key or 0), options.key_name and options.key_name(key) or '',
                pressed and 'down' or 'up', flags, blocked and 'blocked' or '')
        end)
        M.unregister = options.unregister
    end
    M.event('start', os.date('!%Y-%m-%dT%H:%M:%SZ'), options.version or 'test', M.hooks)
    return true
end

function M.stop()
    if not M.enabled then return false end
    M.event('stop')
    M.enabled = false
    remove_image_hooks()
    if key_event and M.unregister then M.unregister(key_event) end
    key_event = nil
    return true
end

function M.status()
    return { enabled = M.enabled, count = count, dropped = dropped, frames = frame, max_gap = max_gap, hooks = M.hooks }
end

function M.dump()
    local lines = {
        '# Trust menu trace v1',
        '# Lua calls only (what Trust asked Windower to draw), not observed pixels.',
        string.format('# started=%.6f frames=%d max_gap=%.4f retained=%d overwritten=%d capacity=%d hooks=%s',
            started, frame, max_gap, count, dropped, M.capacity, tostring(M.hooks)),
        '# key: dik|name|down/up|flags|blocked   ctl: seq|action|age|mode|result',
        '# cursor: view|row|x|y|visible|recreated   scroll: view|x|y   focus: op|class|view',
        '# img.show flag UNTEXTURED = visible with no texture and no colour (draws as a box)',
        '# context: menu_visible|focus|controller_mode',
        '# time(socket.gettime)\tframe\tevent\tid\tvalues',
    }
    local names = {}
    for name in pairs(counters) do names[#names + 1] = name end
    table.sort(names)
    for _, name in ipairs(names) do lines[#lines + 1] = '# '..name..'='..counters[name] end
    for i = 1, count do lines[#lines + 1] = events[(head + i - 2) % M.capacity + 1] end
    return table.concat(lines, '\n')..'\n'
end

function M.save(path, open)
    local ok, body = pcall(M.dump)
    if not ok then return false, body end
    local f, err = (open or io.open)(path, 'wb')
    if not f then return false, err end
    local wrote, werr = f:write(body)
    f:close()
    if not wrote then return false, werr end
    return true
end

-- Returns ok, message for //trust menutrace [on|mark|save|off|status].
function M.command(mode, path, options)
    mode = type(mode) == 'string' and mode:lower() or 'status'
    if mode == 'on' then
        if not M.start(options) then return true, 'Menu trace is already ON' end
        return true, 'Menu trace ON ('..M.hooks..'). Open the menu, reproduce, //trust menutrace mark at the glitch, then //trust menutrace save'
    elseif mode == 'mark' then
        if not M.enabled then return false, 'Menu trace is OFF; use //trust menutrace on first' end
        M.event('MARK')
        return true, 'Menu trace marked'
    elseif mode == 'save' or mode == 'off' then
        if mode == 'off' then M.stop() end
        if count == 0 then return true, 'No menu trace captured' end
        local ok, err = M.save(path, options and options.open)
        if not ok then return false, 'Menu trace save failed: '..tostring(err) end
        return true, 'Menu trace saved: '..path..(mode == 'off' and ' (OFF)' or '')
    elseif mode == 'status' then
        return true, string.format('Menu trace %s; retained=%d, overwritten=%d, frames=%d, max gap %.3f s',
            M.enabled and 'ON' or 'OFF', count, dropped, frame, max_gap)
    end
    return false, 'Usage: //trust menutrace [on|mark|save|off|status]'
end

return M
