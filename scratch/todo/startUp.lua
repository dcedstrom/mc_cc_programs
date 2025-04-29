shell.run("cd todo")
-- Read urls.json and get the code url

print("Reading urls.json...")
local urls_raw = fs.open("urls.json", "r")
local urls = textutils.unserializeJSON(urls_raw.readAll())
urls_raw.close()

local code_url = urls.code

print("Downloading code...")
local code_raw = http.get(code_url)
local code = code_raw.readAll()
code_raw.close()

print("Writing code to todo_display.lua...")
local code_file = fs.open("todo_display.lua", "w")
code_file.write(code)
code_file.close()

print("Running todo display...")
-- Change the file for todo in urls.json to specific todo list if not generic
-- TODO: Add support for multiple types of todo rather than this hack
shell.run("todo_display")
