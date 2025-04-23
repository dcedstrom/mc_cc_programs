
-- TODO: Optionally place torches
-- TODO: Set a "resting" position or hub spot
-- TODO: Handle refueling
-- TODO: Handle lava
-- TODO: Filter denying certain fuels (torches, etc)
-- TODO: Filter denying certain blocks (Tuff, etc)


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

local chestDirection = "west" -- which side relative to starting face is the chest?

function faceChest()
    faceDirection(chestDirection)
end

function dumpInventoryAboveChest()
    -- Step 1: Move above chest
    -- TODO: Since above instead of facing chest direction, need to adjust position
    goTo(0, 1, 0, chestDirection)  -- go to (0,1,0), facing chest

    -- Step 2: Drop items downward into chest
    for i = 1, 16 do
        turtle.select(i)
        turtle.dropDown()
    end

    -- Optional: return to exact (0,1,0), or let goTo(nextPos) handle it
end

function dumpInventory()
    faceChest()
    for i = 1, 16 do
        turtle.select(i)
        turtle.drop()
    end
    faceDirection("north")
end

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

function saveWorkingPosition()
    local file = io.open("lastWorkingPos.txt", "w")
    file:write(position.x .. "," .. position.y .. "," .. position.z .. "," .. getCurrentDirection())
    file:close()
end

function loadWorkingPosition()
    local file = io.open("lastWorkingPos.txt", "r")
    local content = file:read("*a")
    file:close()
    local x, y, z, dir = string.match(content, "(%-?%d+),(%-?%d+),(%-?%d+),(%a+)")
    return {x = tonumber(x), y = tonumber(y), z = tonumber(z), dir = dir}
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

function moveForwardDigging(mineAbove)
    local minePathUp = mineAbove or true
    while not turtle.forward() do
        turtle.dig()
        if minePathUp then
            turtle.digUp()
        end
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

function ensureFuel(minFuel)
    minFuel = minFuel or 100 -- default buffer if not specified
    if turtle.getFuelLevel() == "unlimited" then
        return true
    end

    while turtle.getFuelLevel() < minFuel do
        for i = 1, 16 do
            turtle.select(i)
            if turtle.refuel(1) then
                break
            end
        end

        if turtle.getFuelLevel() < minFuel then
            print("Out of fuel! Insert fuel and press Enter...")
            io.read()
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

function isInventoryFull()
    for i = 1, 16 do
        if turtle.getItemCount(i) == 0 then
            return false
        end
    end
    return true
end



function tableContains(tbl, value)
    for _, v in ipairs(tbl) do
        if v == value then
            return true
        end
    end
    return false -- <- was missing!
end

function selectTrashBlock()
    for i = 1, 16 do
        local item = turtle.getItemDetail(i)
        if item and tableContains(trashBlocks, item.name) then
            turtle.select(i)
            return true
        end
    end
    return false -- none found
end

function goTo(targetX, targetY, targetZ, finalDirection)
    -- Move vertically first
    while position.y < targetY do
        moveUpDigging()
    end
    while position.y > targetY do
        moveDownDigging()
    end

    -- Move in X direction
    if position.x < targetX then
        faceDirection("east")
        for i = 1, targetX - position.x do
            moveForwardDigging()
        end
    elseif position.x > targetX then
        faceDirection("west")
        for i = 1, position.x - targetX do
            moveForwardDigging()
        end
    end

    -- Move in Z direction
    if position.z < targetZ then
        faceDirection("south")
        for i = 1, targetZ - position.z do
            moveForwardDigging()
        end
    elseif position.z > targetZ then
        faceDirection("north")
        for i = 1, position.z - targetZ do
            moveForwardDigging()
        end
    end

    -- Optional: face final direction
    if finalDirection then
        faceDirection(finalDirection)
    end
end

function minePlayerShaft(length)
    for i = 1, length do
        turtle.dig()
        moveForwardDigging()
        turtle.digUp()
        if not turtle.detectDown() then
            if selectTrashBlock() then
                turtle.placeDown()
            else
                print("No trash blocks to place underfoot. Skipping.")
            end
        end
    end
end

-- TODO: Allow selection of turn direction
function stripMine(stripCount, stripLength, startRight)
    for i = 1, stripCount do
        if isInventoryFull() then
            saveWorkingPosition()
            local workPos = loadWorkingPosition()
            returnToStart()
            dumpInventoryAboveChest()
            goTo(workPos.x, workPos.y, workPos.z, workPos.dir)
        end

        minePlayerShaft(stripLength)

        if i < stripCount then
            local turnRightFirst = (i % 2 == 1 and startRight) or (i % 2 == 0 and not startRight)

            if turnRightFirst then
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

local startRight = arg[3] == "true"
stripMine(tonumber(arg[1]), tonumber(arg[2]), startRight)