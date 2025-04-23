function minePlayerShaft(length)
    for i = 1, length do
        turtle.dig()
        while not turtle.forward() do
            turtle.dig()
        end
        turtle.forward()
        turtle.digUp()
    end
end

function stripMine(stripCount, stripLength)
    for i = 1, stripCount do
        minePlayerShaft(stripLength)

        turtle.turnRight()
        minePlayerShaft(3)
        turtle.turnLeft()
    end
end


stripMine(arg[1], arg[2])