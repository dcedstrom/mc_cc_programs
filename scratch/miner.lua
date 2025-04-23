-- TODO: Handle full inventory
-- TODO: Move to original position on various conditions
-- TODO: Move back to working position after inventory is dumped
-- TODO: Optionally place torches
-- TODO: Set a "resting" position or hub spot
-- TODO: Handle refueling

local trashBlocks = {
    "minecraft:cobblestone",
    "minecraft:cobbled_deepslate",
    "minecraft:granite",
    "minecraft:diorite",
    "minecraft:andesite",
    "minecraft:tuff",
    "minecraft:calcite",
    "minecraft:dripstone_block",
}

local directions = {"north", "east", "south", "west"}
local dirIndex = 1 -- north will always be relative to the starting direction

local position = {
    x = 0,
    y = 0,
    z = 0
}

function writePositionToFile()
    local file = io.open("currentPosition.txt", "w")
    file:write(position.x .. "," .. position.y .. "," .. position.z .. "," .. getCurrentDirection())
    file:close()
end


function writeStartingPosition()
    local file = io.open("startingPosition.txt", "w")
    file:write(startingPosition.x .. "," .. startingPosition.y .. "," .. startingPosition.z)
    file:close()
end

function turnLeft()
    turtle.turnLeft()
    dirIndex = (dirIndex - 2) % 4 + 1
end

function turnRight()
    turtle.turnRight()
    dirIndex = (dirIndex % 4) + 1
end

function faceDirection(target)
    while getCurrentDirection() ~= target do
        turnRight()
    end
end

function getCurrentDirection()
    return directions[dirIndex]
end


function moveForward()
    while not turtle.forward() do
        turtle.dig()
    end

    local dir = getCurrentDirection()
    if dir == "north" then
        position.z = position.z - 1
    elseif dir == "south" then
        position.z = position.z + 1
    elseif dir == "east" then
        position.x = position.x + 1
    elseif dir == "west" then
        position.x = position.x - 1
    end

    writePositionToFile()
end

function moveUp()
    if turtle.up() then
        position.y = position.y + 1
        writePositionToFile()
    end
end

function moveDown()
    if turtle.down() then
        position.y = position.y - 1
        writePositionToFile()
    end
end

function moveForwardDigging()
    while not turtle.forward() do
        turtle.dig()
        sleep(0.4) -- slight delay to avoid spamming
    end

    local dir = getCurrentDirection()
    if dir == "north" then
        position.z = position.z - 1
    elseif dir == "south" then
        position.z = position.z + 1
    elseif dir == "east" then
        position.x = position.x + 1
    elseif dir == "west" then
        position.x = position.x - 1
    end

    writePositionToFile()
end

function moveUpDigging()
    while not turtle.up() do
        turtle.digUp()
        sleep(0.4)
    end
    position.y = position.y + 1
    writePositionToFile()
end

function moveDownDigging()
    while not turtle.down() do
        turtle.digDown()
        sleep(0.4)
    end
    position.y = position.y - 1
    writePositionToFile()
end


function readPositionFromFile()
    local file = io.open("currentPosition.txt", "r")
    local content = file:read("*a")
    file:close()
    local x, y, z, dir = string.match(content, "(%-?%d+),(%-?%d+),(%-?%d+),(%a+)")
    position.x, position.y, position.z = tonumber(x), tonumber(y), tonumber(z)
    for i, d in ipairs(directions) do
        if d == dir then
            dirIndex = i
            break
        end
    end
end

function returnToStart()
    -- First align Y (up/down)
    while position.y > 0 do
        moveDownDigging()
    end
    while position.y < 0 do
        moveUpDigging()
    end

    -- Then align X
    if position.x > 0 then
        faceDirection("west")
        for i = 1, position.x do
            moveForwardDigging()
        end
    elseif position.x < 0 then
        faceDirection("east")
        for i = 1, -position.x do
            moveForwardDigging()
        end
    end

    -- Then align Z
    if position.z > 0 then
        faceDirection("north")
        for i = 1, position.z do
            moveForwardDigging()
        end
    elseif position.z < 0 then
        faceDirection("south")
        for i = 1, -position.z do
            moveForwardDigging()
        end
    end

    -- Final orientation
    faceDirection("north")
end



function tableContains(table, value)
    for _, v in ipairs(table) do
        if v == value then
            return true
        end
    end
end

function selectTrashBlock()
    for i = 1, 16 do
        if tableContains(trashBlocks, turtle.getItemDetail(i)['name']) then
            turtle.select(i)
            return
        end
    end
end

function minePlayerShaft(length)
    for i = 1, length do
        turtle.dig()
        moveForwardDigging()
        turtle.digUp()
        if not turtle.detectDown() then
            selectTrashBlock()
            turtle.placeDown()
        end
    end
end

-- TODO: Allow selection of turn direction
function stripMine(stripCount, stripLength)
    for i = 1, stripCount do
        minePlayerShaft(stripLength)

        if i < stripCount then  -- Only move over if not on final strip
            if i % 2 == 1 then
                turnRight()
                minePlayerShaft(3)
                turnRight()
            else
                turnLeft()
                minePlayerShaft(3)
                turnLeft()
            end
        end
    end
    returnToStart()
end


stripMine(tonumber(arg[1]), tonumber(arg[2]))