local font
local font_alt
local test_words
local input_buffer = ""
local word_index = 1
local word_spacing = 40
local line_spacing = 10
local time_until_delete = -1
local lshift_count = 0
local focused = true
local done = false
local time_elapsed = 0.01
local words_typed = 0
local mistakes = 0
local started = false
local filename = "test"
local sliding_x = 0
local sliding_x2 = 0
local tps = 144
local spt = 1 / tps
local accumulator = 0

local invalid_color = {1, .5, .5, 1}
local correct_color = {.6, 1, .7, 1}
local next_color = { .5, .5, .5, 1}
local current_color = {.9, .9, .9, 1}
local done_color = { .5, .5, .5, 1}

function love.load()
    word_index = 1
    time_until_delete = -1
    time_elapsed = .01
    words_typed = 0
    input_buffer = ""
    mistakes = 0
    done = false
    started = false
    sliding_x = 0
    sliding_x2 = -2

    font = love.graphics.newFont("Hack-Regular.ttf", 48, "normal", 2)
    font_alt = love.graphics.newFont("Hack-Regular.ttf", 24, "normal", 2)
    local test_text = love.filesystem.read(filename .. ".txt")
    test_words = string_split(test_text)
    shuffle_list(test_words)
    test_words[#test_words+1] = " "
end

function love.update(dt)
    if done then
        accumulator = accumulator + dt
        while accumulator > spt do
            sliding_x2 = sliding_x2 * 1.08
            accumulator = accumulator - spt
        end
        return
    end
    if not focused or not started then return end
    time_elapsed = time_elapsed + dt
    if time_until_delete > 0 then
        time_until_delete = time_until_delete - dt
        if time_until_delete <= 0 then
            input_buffer = ""
        end
    end
    
    accumulator = accumulator + dt
    while accumulator > spt do
        sliding_x = sliding_x * .95
        accumulator = accumulator - spt
    end
end

function wpm()
    return format_number(words_typed / (time_elapsed / 60))
end

function accuracy()
    local accuracy = 0
    if words_typed + mistakes > 0 then
        accuracy = 100 - (mistakes / (words_typed + mistakes)) * 100
    end
    return format_number(accuracy)
end

function love.draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("WPM: " .. wpm(), font_alt, word_spacing, line_spacing)

    local accuracy_str = "Accuracy: " .. accuracy() .. "%"
    local acc_x = love.graphics.getWidth() - font_alt:getWidth(accuracy_str) - word_spacing
    love.graphics.print(accuracy_str, font_alt, acc_x)

    target_word = test_words[word_index]

    local center_x = love.graphics.getWidth() / 2 - 60
    local target_length = font:getWidth(target_word)
    local word_x = center_x + sliding_x + sliding_x2

    local center_y = love.graphics.getHeight() / 2
    local target_height = font:getHeight()
    local word_y = center_y - target_height / 2

    love.graphics.print({current_color, target_word}, font, word_x, word_y)

    -- Draw previous words
    local cursor_x = word_x
    local cursor_y = word_y
    local i = word_index - 1
    while i > 0 do
        local word = test_words[i]
        cursor_x = cursor_x - word_spacing - font:getWidth(word)
        love.graphics.print({done_color, word}, font, cursor_x, cursor_y)
        love.graphics.print({correct_color, word}, font, cursor_x, cursor_y + line_spacing + target_height)
        i = i - 1
    end

    -- Draw next words
    cursor_x = word_x + target_length + word_spacing
    cursor_y = word_y
    i = word_index + 1
    while i < #test_words + 1 do
        local word = test_words[i]
        love.graphics.print({next_color, word}, font, cursor_x, cursor_y)
        cursor_x = cursor_x + word_spacing + font:getWidth(word)
        i = i + 1
    end

    -- Draw input buffer
    cursor_y = word_y + font:getHeight() + line_spacing
    cursor_x = word_x
    for i = 1, #input_buffer do
        local c = string.sub(input_buffer, i, i)
        if c == string.sub(target_word, i, i) then
            love.graphics.print({correct_color, c}, font, cursor_x, cursor_y)
        else
            love.graphics.print({invalid_color, c}, font, cursor_x, cursor_y)
        end
        cursor_x = cursor_x + font:getWidth(c)
    end
end

function love.keypressed(key)
    if key == "lshift" then
        lshift_count = lshift_count + 1
        if lshift_count == 3 then
            love.load()
            lshift_count = 0
        end
    else
        started = true
        lshift_count = 0
    end
    if key == "backspace" then
        input_buffer = string.sub(input_buffer, 1, #input_buffer - 1)
    end
end

function love.textinput(text)
    if done or text == " " then return end
    started = true
    input_buffer = input_buffer .. text
    if input_buffer == test_words[word_index] then
        sliding_x = sliding_x + font:getWidth(test_words[word_index]) + word_spacing
        word_index = word_index + 1
        input_buffer = ""
        words_typed = words_typed + 1

        if word_index == #test_words then
            save_score(filename, wpm(), accuracy())
            done = true
        end
    elseif partial_match(input_buffer, test_words[word_index]) then
        -- Ignore
    elseif time_until_delete >= 0 then
        time_until_delete = .4
    else
        time_until_delete = .4
        mistakes = mistakes + 1
    end
end

function love.focus(f)
    focused = f
end

function string_split(str)
    t = {}
    for k in string.gmatch(str, "[^%s]+") do
        t[#t+1] = k
    end
    return t
end

function shuffle_list(list)
    for i = #list, 2, -1 do
        local j = love.math.random(i)
        list[i], list[j] = list[j], list[i]
    end
end

function partial_match(str1, str2)
    for i = 1,math.min(#str1, #str2) do
        if string.sub(str1, i, i) ~= string.sub(str2, i, i) then
            return false
        end
    end
    return true
end

function format_number(num)
    return string.format("%.1f", num)
end

function save_score(file, wpm, accuracy)
    local score_filename = file .. "_score.txt"
    local score_row = os.date("%m/%d %H:%M:%S ") .. wpm .. " " .. accuracy .. "\n"
    
    local f = love.filesystem.newFile(score_filename, "a")
    f:write(score_row)
    f:close()
end