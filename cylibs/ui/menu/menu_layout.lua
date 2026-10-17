-- Keep the editor beside the command menu; derive coordinates from each
-- view's actual width, rather than a desktop-resolution-specific offset.
local Layout = {}

function Layout.positions(screenWidth, screenHeight, width, height, adjacent)
    local menuX = math.max(8, screenWidth - 128)
    local x, y = 16, 48
    if adjacent then
        x, y = menuX - 8 - width, 52
    end
    x = math.max(8, math.min(x, math.max(8, screenWidth - width - 8)))
    y = math.max(8, math.min(y, math.max(8, screenHeight - height - 8)))
    return x, y, menuX, 52
end

return Layout
