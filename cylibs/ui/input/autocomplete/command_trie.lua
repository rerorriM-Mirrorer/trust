local Node = {}
Node.__index = Node

function Node.new()
    local self = setmetatable({}, Node)
    self.command = nil
    self.children = T{}
    return self
end

local CommandTrie = {}
CommandTrie.__index = CommandTrie

function CommandTrie.new()
    local self = setmetatable({}, CommandTrie)
    self.root = Node.new()
    return self
end

function CommandTrie:addCommand(text)
    if text == nil or text:length() == 0 then
        return
    end

    local node = self.root

    -- Normalize only trie lookup keys; keep the original command string
    -- in each leaf so suggestions preserve display casing (mode names, etc).
    local lookup = text:lower()
    for i = 1, lookup:length() do
        local childNode = node.children[lookup[i]]
        if childNode == nil then
            childNode = Node.new()
            node.children[lookup[i]] = childNode
        end
        node = childNode
    end
    node.command = text
end

function CommandTrie:getCommands(prefix)
    local node = self.root

    local lookup = prefix:lower()
    for i = 1, lookup:length() do
        local childNode = node.children[lookup[i]]
        if childNode then
            node = childNode
        else
            return L{}
        end
    end

    local commands = L{}

    -- Return all leaf nodes under node
    local stack = L{ node }
    while not stack:empty() do
        local node = stack:remove(stack:length())
        if node.command then
            commands:append(node.command)
        end
        for _, childNode in pairs(node.children) do
            stack:append(childNode)
        end
    end

    return commands:compact_map()
end

return CommandTrie