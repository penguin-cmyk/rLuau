return {
    error = function(error_message: string, level: number)
        if level == 1 then 
            if warn == nil then 
                print(`\27[33m{error_message}\27[0m\n`)
            else 
                warn(error_message)
            end 
        elseif level == 2 then
            error(error_message,2) 
        end
    end,
    remove_white = function(code: string)
        return string.gsub(code , " ", "")
    end 
}