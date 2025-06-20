function message(text, to_log)
    if (text == nil or #text < 1) then
        return
    end

    if (to_log) then
        log(text)
    else
        windower.add_to_chat(207, _addon.name .. ": " .. text)
    end
end

return message
