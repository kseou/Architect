-- Import the chalk library for colored console output
local chalk = require("chalk")
local Architect = {}
local version = "Architect version - v0.1"

-----------------------------------
-- ARCHITECT HELPER FUNCTIONS
-----------------------------------

--- Function to determine compiler flags based on file types.
-- @param sourceFiles List of source files.
-- @return Compiler flags based on file types.
local function getFileTypeFlags(sourceFiles)
    -- Iterate through source files to determine file types
    for _, file in ipairs(sourceFiles) do
        local extension = file:match("%.([^%.]+)$")
        -- Return appropriate compiler based on file extension
        if extension == "c" then
            return "gcc"
        elseif extension == "cpp" or extension == "cc" or extension == "cxx" or extension == "c++" or extension == "cp" then
            return "g++"
        end
    end
    return "" -- Default to an empty string if no specific flags are needed
end

--- Detect system compiler or return g++.
-- @param params Architect parameters.
-- @return Compiler to be used.
local function detectSystemCompiler(params)
    local cc = os.getenv("CC") -- Check the CC environment variable
    if cc then
        return cc
    end

    -- Return compiler determined by file types if CC is not set
    if params and params.sourceFiles then
        return getFileTypeFlags(params.sourceFiles)
    else
        return ""
    end
end

--- Function to get library flags using pkg-config.
-- @param libs List of libraries.
-- @return Library flags using pkg-config.
local function getPkgConfigLibs(libs)
    if not libs or #libs == 0 then
        return ""
    end

    local pkgConfigCommand = "pkg-config --cflags --libs " .. table.concat(libs, " ")
    local handle = io.popen(pkgConfigCommand)

    if not handle then
        return "" -- Return empty string on error
    end

    local pkgConfigOutput, pkgConfigError = handle:read("*a")
    handle:close()

    if pkgConfigOutput then
        return pkgConfigOutput:sub(1, -2) -- Remove the trailing newline
    else
        print(chalk.red.bold("Error: ") .. (pkgConfigError or "Unknown error occurred... Exiting!"))
        return "" -- Return empty string if there's an error
    end
end

--- Function to check if a file exists.
-- @param fileName Name of the file to check.
-- @return True if the file exists, false otherwise.
local function fileExists(fileName)
    local file = io.open(fileName, "r")

    if file then
        file:close()
        return true
    else
        return false
    end
end

----------------------------------
-- ARCHITECT CORE FUNCTIONS
----------------------------------

--- Function to run arbitrary shell commands using io.popen.
-- @param commands List of commands to execute.
-- @return True if all commands are successful, false otherwise.
local function runCommands(commands)
    local allSuccessful = true

    for _, command in ipairs(commands) do
        local handle = io.popen(command)
        if handle then
            local output = handle:read("*a")

            if output and output ~= "" then
                print(chalk.yellow.bold("Info: ") .. chalk.white.bold("Command output: "  .. output))
            end

            local success, status, code = handle:close()

            if success then
                print(chalk.green.bold("Info: ") .. chalk.white.bold("Command successful: " .. command))
            else
                print(chalk.red.bold("Error: Command failed: ") .. command)
                print(chalk.red.bold("Exit status: ") .. (status or "unknown"))
                print(chalk.red.bold("Exit code: ") .. (code or "unknown"))
                allSuccessful = false
            end
        else
            print(chalk.red.bold("Error: ") .. chalk.white.bold("Unable to execute command."))
            allSuccessful = false
        end
    end

    return allSuccessful
end

--- Function to execute a task (set of commands).
-- @param task Task containing commands to execute.
local function executeTask(task)
    if task.commands then
        local success = runCommands(task.commands)
        if not success then
            print(chalk.red.bold("Error: Task '" .. task.name .. "' failed."))
        end
    else
        print(chalk.red.bold("Error: Task '" .. task.name .. "' does not have a 'commands' field."))
    end
end

--- Function to build the project based on provided parameters.
-- @param params Architect parameters.
local function build(params)
    local params = params or {} -- Ensure params table exists
    local sourceFiles = params.sourceFiles or {}
    local outputExecutable = params.outputExecutable or "a.out"
    local compiler = params.compiler or detectSystemCompiler(params)
    local compilerFlags = params.compilerFlags or ""
    local additionalFlags = params.additionalFlags or ""
    local libs = params.libs or ""
    local outputFolder = params.outputFolder or ""

    local pkgConfigLibs = getPkgConfigLibs(libs)

    if #sourceFiles > 0 and outputExecutable ~= "" and compiler ~= "" then
        
        -- Check if the output folder exists, create it if not
        if outputFolder ~= "" and not fileExists(outputFolder) then
            os.execute("mkdir " .. outputFolder)
        end
        
        local outputPath = outputFolder ~= "" and (outputFolder .. "/" .. outputExecutable) or outputExecutable

        local command = compiler .." " ..table.concat(sourceFiles, " ") .." " .. compilerFlags .. " " .. pkgConfigLibs .. " " .. additionalFlags .. " -o " .. outputPath
        print(chalk.yellow.bold("Info: ") .. chalk.white.bold("Building command: ") .. command .. "\n")

        local success = os.execute(command)

        if success == true or success == 0 then
            print(chalk.green.bold("Success: ") .. chalk.white.bold("Build complete! ") .. "🎉")

            -- Run commands only if both sourceFiles and commands exist
            if params.commands then
                runCommands(params.commands)
            end
        else
            print(chalk.red.bold("Error: Build failed!") .. " 😞 " .. chalk.white.bold("Please don't bully me and check your parameters!"))
        end
    elseif params.commands then
        -- Print out the "Info" message for commands only
        print(chalk.yellow.bold("Info: ") .. chalk.white.bold("Executing commands without building."))
        runCommands(params.commands)
    else
        print(chalk.red.bold("Error: Not enough information provided for build or commands. Please check your parameters!"))
    end
end

--- Function to remove the executable and, if applicable, the output folder.
-- @param params Architect parameters.
local function clean(params)
    local params = params or {} -- Ensure params table exists
    local outputExecutable = params.outputExecutable or "a.out"
    local outputFolder = params.outputFolder or ""

    local executablePath = outputFolder ~= "" and (outputFolder .. "/" .. outputExecutable) or outputExecutable

    local executableExists = fileExists(executablePath)

    -- Check if the executable exists and remove it if it does
    if executableExists then
        os.remove(executablePath)
        print(chalk.green.bold("Success: ") .. chalk.white.bold("Clean complete!"))
    end

    -- Check if the output folder exists and remove it if it's empty or doesn't contain the executable
    if outputFolder ~= "" and fileExists(outputFolder) then
        local files = io.popen("ls " .. outputFolder):read("*a")
        if files == "" or not executableExists then
            os.execute("rmdir " .. outputFolder)
            print(chalk.green.bold("Success: ") .. chalk.white.bold("Output folder '" .. outputFolder .. "' removed (empty or missing executable)."))
        end
    end

    -- Print an error message if neither the executable nor the output folder exists
    if not executableExists and (outputFolder == "" or not fileExists(outputFolder)) then
        print(chalk.red.bold("Error: ") .. chalk.white.bold("File '" .. executablePath .. "' does not exist, and output folder '" .. outputFolder .. "' does not exist. Unable to clean!"))
    end
end

--- Function to run specific tasks based on user input.
-- @param taskList List of tasks.
function Architect.runTasks(taskList)
    local taskName = arg[1]

    if not taskName then
        print(chalk.red.bold("Error: ") .. chalk.white.bold("Please provide a task name."))
        return
    end

    local found = false

    if taskList[taskName] then
        executeTask(taskList[taskName])
        found = true
    end

    if not found then
        print(chalk.red.bold("Error: ") .. chalk.white.bold("Task '") .. chalk.white.bold(taskName) .. "'" .. chalk.white.bold(" not found."))
    end
end

--- Function to plan and execute actions based on command-line input.
-- @param params Architect parameters.
function Architect.plan(params)
    local action = arg[1]

    if action == "--build" then
        build(params)
    elseif action == "--clean" then
        clean(params)
    elseif action == "--version" then
        print(version)
    else
        print(chalk.white.bold("Architect Usage: [--build | --clean | --version]"))
    end
end

-- Return the Architect table with all functions
return Architect
