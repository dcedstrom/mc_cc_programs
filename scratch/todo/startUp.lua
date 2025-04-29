local baseDir = "./todo"
print("Reading urls.json...")
local urls_raw = fs.open(fs.combine(baseDir, "urls.json"), "r")
local urls = textutils.unserializeJSON(urls_raw.readAll())
urls_raw.close()

local code_url = urls.code

print("Downloading code...")
local code_raw = http.get(code_url)
local code = code_raw.readAll()
code_raw.close()

print("Writing code to todo_display.lua...")
local code_file = fs.open(fs.combine(baseDir, "todo_display.lua"), "w")
code_file.write(code)
code_file.close()

print("Running todo display...")
-- Change the file for todo in urls.json to specific todo list if not generic
-- TODO: Add support for multiple types of todo rather than this hack
shell.run("cd todo")
shell.run("todo_display")
