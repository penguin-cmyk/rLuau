
local globals: { any } = require("./globals.luau")
local types: { any } = require("./types.luau")
local utils: { any } = require("./utils.luau")

local CodeExecution: { string } = {}
local LocalVariables: { string } = {}

-- rLoad for rust load btw
local function rLoad(input_table: { any }, code: string)
    local env_defined: boolean = false
    local current_pos: number = 1
    local length: number = #code
    
    local self: { any } = setmetatable({},{})
    self.globals = globals

    function self:increment(amount: number)
        current_pos = current_pos + amount
    end

    function self:peek(offset: number, length: number): string
        return code:sub(current_pos + offset, current_pos + offset + length - 1)
    end

    function self:get_current_char(): string
        return code:sub(current_pos, current_pos)
    end 
    
    function self:collect_chars(end_character: string): string 
        local collect_chars: string = ""
        local nesting_level: number = 0
    
        while current_pos <= length do
            local current_char = self:get_current_char()
            if current_char == end_character and nesting_level == 0 then
                break
            elseif current_char == "{" or current_char == "(" or current_char == "[" then
                nesting_level = nesting_level + 1
            elseif current_char == "}" or current_char == ")" or current_char == "]" then
                nesting_level = nesting_level - 1
            end
    
            collect_chars = collect_chars .. current_char
            self:increment(1)
        end
    
        return collect_chars
    end

    function self:expect(character: string, error_message: string)
        if self:get_current_char() ~= character then 
            utils.error(error_message,2)
        end  
        self:increment(1) 
    end
    
    function self:get_variable_name(): string 
        local collected: string = self:collect_chars("=")
        local variable: { string } = collected:split(":")

        local variable_name: string = variable[1]
        table.insert(LocalVariables,variable_name)

        local output_value: string = variable[2] ~= nil and `{variable_name}: {types.get_type(utils.remove_whitespace(variable[2]))}` or `{utils.remove_whitespace(variable_name)}`

        self:increment(1)
        return output_value  
    end 

    function self:get_params(): string
        local collected: string = self:collect_chars(")")
        local params: { string } = collected:split(",")
        
        local Params: { string } = {}

        for _, param in pairs(params) do 
            local splitted_param = param:split(":")
            if #splitted_param > 1 then 
                local param_name = splitted_param[1]
                local param_type = string.gsub(splitted_param[2]," ","")
                
                table.insert(Params,`{param_name}: {types.get_type(param_type)}`)
            else 
                table.insert(Params,param)
            end 
        end 
        self:increment(1)
        return table.concat(Params,",")
    end

    function self:insert_code(code: string, skip: number)
        table.insert(input_table,code)
        self:increment(skip)
    end

    function self:is_global_variable(name: string): boolean
        return table.find(self.globals, name) ~= nil
    end

    function self:collect_identifier(): string
        local identifier: string = ""
        while current_pos <= length do
            local char = self:get_current_char()
            if char:match("%w") or char == "_" then
                identifier = identifier .. char
                self:increment(1)
            else
                break
            end
        end
        return identifier
    end

    function self:handle_function(is_public: boolean?)
        if is_public then
            self:increment(7) -- skip whitespace ("pub fn ")
        else 
            self:increment(3)
        end 
        local function_name = self:collect_chars("(")
        self:increment(1)
        local params = self:get_params()
        self:increment(1)

        self:expect("{","Expected { got "..self:get_current_char().." (for fn)")
        local code = self:collect_chars("}")
        local scope_code = rLoad({},code)
        local function_start = if is_public then `function {function_name}({params})` else  `local function {function_name}({params})`

        self:insert_code(function_start,1)
        for _,code in pairs(scope_code) do 
            self:insert_code(`\t{code}`,0)
        end 
        self:insert_code(`end`,1)

        table.insert(self.globals,function_name) 
    end 

    function self:handle_scope(insert_code: string)
        local scope_code: string = self:collect_chars("}")
        local scope_code: { string } = rLoad({},scope_code) -- shadowed over scope_code since its useless to make a different variable for it

        self:insert_code(`{insert_code}`,1)
        for _,code in pairs(scope_code) do 
            self:insert_code(`\t{code}`,0)
        end 

        self:insert_code("end",0)
    end 

    function self:handle_use(split_method: string, callback)
        self:increment(1)
        local Services: { string } = self:collect_chars("}"):split(split_method)
        for _, service in pairs(Services) do
            local result = callback(service)
            if not table.find(input_table,result) then  
                table.insert(input_table,result)
                table.insert(self.globals,service)

            else 
                utils.error(`-- Double declaration of "{service}" found, ignoring duplicate`,1)
            end 
        end 
    end 

    function self:handle_match()
        self:increment(6) -- Skip "match "
        local variable = self:collect_chars("{")
        self:increment(1) -- Skip "{"
      
        local match_code_block: string = self:collect_chars("}")
        local splitted: { string } = match_code_block:split(",")
        
        local output_value: string = ""
      
        for i, v in pairs(splitted) do
          local combined = (i .. v):split("=>")
          if combined[2] ~= nil then
            local expected: string = combined[1]
            local code: string = combined[2]
            
            -- remove whitespaces and weird new lines
            local string: string = string.gsub(expected, " ", ""):gsub("\n", "")
            local expected: string = string:sub(2, #string)
            
            local addiontinal_methods: { string } = variable:split(".")
            
            -- So it will auto translate it into the specific string
            if #addiontinal_methods == 2 then 
                local method = addiontinal_methods[2]:gsub(" ","")
                variable = variable:gsub("."..method,""):split("()")[1]
                if method == "to_lowercase()" then
                    variable =  (`{variable}:lower()`)
                    expected = expected:lower()
                elseif method == "to_uppercase()" then 
                    variable =  (`{variable}:upper()`)
                    expected = expected:upper()
                end     
            end     

            local code_table: { string } = {}
            local code_str: string = ""

            rLoad(code_table, code)

            for _,code in pairs(code_table) do 
                code_str = code_str..`\t\t{code}\n`
            end 
      
            if i == 1 then
              output_value =
                `if {variable} == {expected} then\n{code_str}\n`
            elseif expected == "_" then 
                output_value =
                output_value ..
                `\t\telse\n\t{code_str}\n`
            else 
              output_value =
                output_value ..
                `\t\telseif {variable} == {expected} then\n\t{code_str}\n`
            end
          end
        end
        output_value = output_value .. "end"
      
        self:insert_code(output_value, 0)
      end
      

    while current_pos <= length do
        local current_char = self:get_current_char()
        if self:peek(0, 7) == "println" then
            self:increment(7)

            self:expect("!",`Expected ! got {self:get_current_char()} (for print)`)
            self:expect("(",`Expected ( got {self:get_current_char()} (for print)`)

            local chars = self:collect_chars(")")
            self:insert_code(`print({chars})`,1)
        elseif self:peek(0,3) == "pub" and string.gsub(self:peek(3,4)," ","")== "fn" then 
            self:handle_function(true)
        elseif self:peek(0,2) == "fn" then 
            self:handle_function(false)
        elseif self:peek(0,3) == "let" then 
            self:increment(4)

            local variable_name = self:get_variable_name()
            local variable_value = self:collect_chars("\n")

            local output_value = string.gsub(variable_value,"Instance::new","Instance.new")
            output_value = (output_value:gsub("::",":")):gsub("!:",".")
            local multi_line_string = output_value:split('r#"')
            if #multi_line_string > 1 then 
                local value = self:collect_chars('"')
                output_value = `= [[{value}]]`
            end 

            self:insert_code(`local {variable_name} = {output_value}`,1)
        elseif self:peek(0,4) == "loop" then
            self:increment(5)

            self:expect("{",`Expected "" got {self:get_current_char()} (for loop)`)
            self:handle_scope(`while true do`)
        elseif self:peek(0,5) == "while" then 
            self:increment(6) -- skip ze whitespaze 
            local condition = self:collect_chars("{")
            self:increment(1)
            self:handle_scope(`while {string.gsub(condition,"::",":")}do`)
        elseif self:peek(0,3) == "for" then 
            self:increment(4)

            local condition = self:collect_chars("{")
            local is_range = condition:split("..")
            local is_loop = condition:split("in")

            if #is_range == 2 then 
                local first_range,second_range = is_range[1],is_range[2]
                self:increment(1)
                self:handle_scope(`for i = {first_range}, {second_range} do`)
                return 
            elseif #is_loop == 2 then 
                local value_name,array = is_loop[1],is_loop[2]
                local fixed_array = string.gsub(array," ","");
                self:handle_scope(`for i,{value_name}in pairs({string.gsub(fixed_array,"::",":")}) do`)
            else 
                utils.error("Invalid Handling of for loop?",2)
            end 
        elseif self:peek(0,2) == "if" then 
            self:increment(3) -- if 
            local condition = ((self:collect_chars("{")):gsub("!::",".")):gsub("::",":")
            local if_code = {}
            
        elseif self:peek(0,5) == "match" then 
            self:handle_match()     
        elseif self:peek(0,3) == "use" then 
            self:increment(4)
            local services_use = self:collect_chars("{")
            if services_use == "services::" then 
                self:handle_use(",",function(service)
                    return `local {service} = game:GetService("{service}")`
                end)
            elseif services_use == "task::" then 
                self:handle_use(",",function(func)
                    return `local {func} = task.{func:lower()}`
                end)
            elseif services_use == "global::" then 
                self:handle_use(",",function(global)
                    print(global)
                    if global == "env" then 
                        env_defined = true 
                        return `local env = getgenv()`
                    else 
                        if not env_defined then 
                            return utils.error("Please define env before using other global functions\n",1)
                        end 

                        return `local {global} = env.{global}`
                    end 
                end)
            end 
            self:increment(1)
        elseif current_char == "'" then 
            self:insert_code("'",1)
        elseif current_char == '"' then 
            self:insert_code('"',1)
        elseif current_char == ';' then 
            self:increment(1)
        elseif self:peek(0,2) == "::" then
            print("oki")
            local collected = string.gsub(self:collect_chars("\n"),"::",":")
            self:insert_code(collected,2)
        elseif self:peek(0,2) == "//" then 
            self:increment(3)
            local collected = self:collect_chars("\n")
            self:insert_code(`-- {collected}`,0)
        else
            local identifier = self:collect_identifier()
            if identifier ~= "" then

                if self:is_global_variable(identifier) then
                    print("GLOBAL",identifier)
                    if identifier == "Instance" then
                        if self:peek(0,2) ~= "::" then 
                            utils.error("expected :: on Instance::new",2)
                        end     
                        self:increment(2)
                        if self:peek(0,3) ~= "new" then 
                            utils.error("expected new after Instance",2)
                        end 
                        self:increment(4) -- Skip (

                        local collect = self:collect_chars(")")
                        local Instance_new_args = collect:split(",")

                        self:insert_code(`Instance.new({Instance_new_args[1]},{Instance_new_args[2]})`,1)
                    elseif self:get_current_char() == "(" then
                        local collected_chars = self:collect_chars("\n")
                        self:insert_code(`{identifier}{collected_chars}`,1)
                    elseif self:peek(0, 2) == "::" then
                            self:increment(2)
                            local method = self:collect_identifier()
                            self:expect("(", "Expected ( after method call")
                            local args = self:collect_chars(")")
                            self:increment(1)
                            local formatted_args = args:gsub("::", ":")
                            print(`{identifier}:{method}({formatted_args})`)
                            self:insert_code(`{identifier}:{method}({formatted_args})`, 1)
                    else
                        local collected = string.gsub(self:collect_chars("\n"),"::",":")
                        self:insert_code(`{identifier}{collected}`,1)
                    end
                elseif table.find(LocalVariables,identifier) then 
                    local collected_chars = self:collect_chars("\n");
                    local collected_real = collected_chars:gsub("!::",".")
                    local collected = string.gsub(collected_real,"::",":")
                    print(collected)
                    if #collected ~= 0 then  
                        self:insert_code(identifier..collected,0)
                    else 
                        self:insert_code(identifier,0)
                    end 
                else 
                    self:increment(#identifier)
                end
            else
                self:increment(1)
            end
        end
    end

    return input_table
end

return {
    translate = function(code: string)
        print(("\n"):rep(50))
        local code = rLoad(CodeExecution,code);
        local codi = table.concat(CodeExecution,"\n")
        
        for previous,nextvalue in pairs(types.Replacements) do
            codi = codi:gsub(previous,nextvalue)
        end

        return codi.."\n--Call Main function\nif rawequal(main,nil) then\n\terror('Please define main using fn main {}')\nend\nmain()"
    end,
}
