local translator = require("./helpers/handler")

local stdio = require("@lune/stdio")
local fs = require("@lune/fs")

while true do 
    local choice: number = stdio.prompt("confirm", " Reload code?")
    if choice then 
        local translated = translator.translate(fs.readFile("main.rs"))
        fs.writeFile("output.luau","--!nocheck\n"..translated);
    end 
end 
