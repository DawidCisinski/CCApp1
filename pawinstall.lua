local PARMS = { ... }

local USER = nil
local REPO = nil

if not USER or not REPO then
    if not PARMS[2] then
        print("pawlib [user] [repo]")
        error("Missing parameters", 0)
    end
    USER = PARMS[1]
    REPO = PARMS[2]
end

local function file_exp(file)
    if file:sub(#file - 3, #file) == ".txt" then return ".txt" end
    if file:sub(#file - 3, #file) == ".lua" then return ".lua" end
    return false
end

local function getUrl(user, repo, file)
    return "https://raw.githubusercontent.com/" .. user .. "/" .. repo .. "/main/" .. textutils.urlEncode(file)
end

local function get(file)
    local h = http.get(getUrl(USER, REPO, file))
    if not h then error("HTTP request failed", 0) end
    local data = h.readAll()
    h.close()
    if not data then error("Empty file data", 0) end
    return data
end

local function prepareFolder(path)
    if fs.exists(path) then
        if fs.isDir(path) then
            fs.delete(path)
            fs.makeDir(path)
        else
            error("Path exists but is not a directory", 0)
        end
    else
        fs.makeDir(path)
    end
end

local function save(file, data)
    local f = fs.open(file, "w")
    if not f then error("Cannot open file for writing", 0) end
    f.write(data)
    f.close()
end

local program = textutils.unserialize(get("PAWINSTALL_DATA.txt"))
if not program then error("Invalid PAWINSTALL_DATA format", 0) end

local appFolder = program.programName:gsub(" ", "") .. "Data"
prepareFolder(appFolder)

local mainExists = false
for i, file in ipairs(program.programFiles) do
    if file == program.mainFile then
        mainExists = true
    end
end
if not mainExists then error("mainFile not found in programFiles", 0) end

for i, file in ipairs(program.programFiles) do
    if file_exp(file) then
        save(appFolder .. "/" .. file, get(file))
    else
        error("Unsupported file extension: " .. file, 0)
    end
end

save(program.programName .. ".lua", 'shell.run("' .. appFolder .. "/" .. program.mainFile .. '")')
print("!Installation complete " .. program.programName .. " version: " .. program.version)
