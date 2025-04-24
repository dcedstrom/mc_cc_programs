-- local json = require("json")


-- TODO: Should this always be relative or should main() take a path optionally?
local basePath = shell.dir()

local function loadUrls(filename)
    local fp = filename or "urls.json"
    print("Loading urls from " .. fs.combine(basePath, fp))
    local file = fs.open(fs.combine(basePath, fp), "r")
    if not file then
        error("Failed to open file")
    end
    local content = file.readAll()
    file.close()

    local parsed = textutils.unserializeJSON(content)
    return parsed
end

local function loadTasks(filename)
    local fp = filename or "tasks.json"
    print("Loading tasks from " .. fs.combine(basePath, fp))
    local file = fs.open(fs.combine(basePath, fp), "r")
    if not file then
        error("Failed to open file")
    end

    local content = file.readAll()
    file.close()

    local parsed = textutils.unserializeJSON(content)
    if not parsed then
        error("Failed to parse tasks")
    end
    return parsed.tasks
end

local monitor = peripheral.find("monitor")

if not monitor then
    error("No monitor found")
end


monitor.setTextScale(1)
monitor.clear()
monitor.setCursorPos(1, 1)

local function drawTask(task, indent)
    indent = indent or 0
    local indentStr = string.rep("  ", indent)
    
    -- Check if we're about to overflow before writing the main task
    -- TODO: Implement paging
    local _, y = monitor.getCursorPos()
    local _, height = monitor.getSize()
    if y > height then return end

    monitor.setTextColor(colors.white)
    monitor.write(indentStr .. "- " .. task.name)
    monitor.setCursorPos(1, y + 1)

    if type(task.subtasks) == "table" then
        for _, sub in ipairs(task.subtasks) do
            local _, y = monitor.getCursorPos()
            if y > height then return end

            monitor.setTextColor(sub.done and colors.green or colors.yellow)
            local checkbox = sub.done and "[x]" or "[ ]"
            monitor.write(indentStr .. "  " .. checkbox .. " " .. sub.name)
            monitor.setCursorPos(1, y + 1)
        end
    end
end

local function getTasksFromGit(taskUrl)
    
    print("Getting tasks from " .. taskUrl)
    local url = taskUrl
    local res = http.get(url)
    if res then
        local data = res.readAll()
        res.close()

        local f = fs.open(fs.combine(basePath, "tasks.json"), "w")
        print("Writing tasks to " .. fs.combine(basePath, "tasks.json"))
        f.write(data)
        f.close()

        return true
    else
        print("Failed to fetch tasks from GitHub.")
        return false
    end
end

local urls = loadUrls()

local function displayTasks(taskList)
    print("Displaying tasks")
    monitor.clear()
    monitor.setCursorPos(1, 1)
    for _, task in ipairs(taskList) do
        drawTask(task, 0)
    end
end

local function main()
    while true do
        if getTasksFromGit(urls["tasks"]) then
            local tasks = loadTasks()
            displayTasks(tasks)
        end
        sleep(60)
    end
end


main()