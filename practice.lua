local practice = {
    font = love.graphics.newFont("Hack-Regular.ttf", 48, "normal", 2),
    font_alt = love.graphics.newFont("Hack-Regular.ttf", 24, "normal", 2),
    test_words = {},
    input_buffer = "",
    word_index = 1,
    word_spacing = 40,
    line_spacing = 10,
    time_until_delete = -1,
    lshift_count = 0,
    focused = true,
    done = false,
    time_elapsed = 0.01,
    words_typed = 0,
    mistakes = 0,
    started = false,
    left_shift = 0,
    right_shift = 0,
    tps = 144,
    spt = 1 / 144,
    accumulator = 0,
    invalid_color = {1, .5, .5, 1},
    correct_color = {.6, 1, .7, 1},
    next_color = { .5, .5, .5, 1},
    current_color = {.9, .9, .9, 1},
    done_color = { .5, .5, .5, 1},
    args = {}
}


function practice:load(args)
    args = args or self.args
    self.word_index = 1
    self.time_until_delete = -1
    self.time_elapsed = .01
    self.words_typed = 0
    self.input_buffer = ""
    self.mistakes = 0
    self.done = false
    self.started = false
    self.left_shift = 0
    self.right_shift = -2
    self.filepath = args[1]
    self.exercise_name = args[2]
    self.args = args

    local test_text = love.filesystem.read(self.filepath)
    self.test_words = self:string_split(test_text)
    self:shuffle_list(self.test_words)
    self.test_words[#self.test_words+1] = " "
end

function practice:update(dt)
    if self.done then
        self.accumulator = self.accumulator + dt
        while self.accumulator > self.spt do
            self.right_shift = self.right_shift * 1.08
            self.accumulator = self.accumulator - self.spt
        end
        return
    end
    if not self.focused or not self.started then return end
    self.time_elapsed = self.time_elapsed + dt
    if self.time_until_delete > 0 then
        self.time_until_delete = self.time_until_delete - dt
        if self.time_until_delete <= 0 then
            self.input_buffer = ""
        end
    end
    
    self.accumulator = self.accumulator + dt
    while self.accumulator > self.spt do
        self.left_shift = self.left_shift * .95
        self.accumulator = self.accumulator - self.spt
    end
end

function practice:wpm()
    return self:format_number(self.words_typed / (self.time_elapsed / 60))
end

function practice:accuracy()
    local accuracy = 0
    if self.words_typed + self.mistakes > 0 then
        accuracy = 100 - (self.mistakes / (self.words_typed + self.mistakes)) * 100
    end
    return self:format_number(accuracy)
end

function practice:draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("WPM: " .. self:wpm(), self.font_alt, self.word_spacing, self.line_spacing)

    local accuracy_str = "Accuracy: " .. self:accuracy() .. "%"
    local acc_x = love.graphics.getWidth() - self.font_alt:getWidth(accuracy_str) - self.word_spacing
    love.graphics.print(accuracy_str, self.font_alt, acc_x)

    self.target_word = self.test_words[self.word_index]

    local center_x = love.graphics.getWidth() / 2 - 60
    local target_length = self.font:getWidth(self.target_word)
    local word_x = center_x + self.left_shift + self.right_shift

    local center_y = love.graphics.getHeight() / 2
    local target_height = self.font:getHeight()
    local word_y = center_y - target_height / 2

    love.graphics.print({self.current_color, self.target_word}, self.font, word_x, word_y)

    -- Draw previous words
    local cursor_x = word_x
    local cursor_y = word_y
    local i = self.word_index - 1
    while i > 0 do
        local word = self.test_words[i]
        cursor_x = cursor_x - self.word_spacing - self.font:getWidth(word)
        love.graphics.print({self.done_color, word}, self.font, cursor_x, cursor_y)
        love.graphics.print({self.correct_color, word}, self.font, cursor_x, cursor_y + self.line_spacing + target_height)
        i = i - 1
    end

    -- Draw next words
    cursor_x = word_x + target_length + self.word_spacing
    cursor_y = word_y
    i = self.word_index + 1
    while i < #self.test_words + 1 do
        local word = self.test_words[i]
        love.graphics.print({self.next_color, word}, self.font, cursor_x, cursor_y)
        cursor_x = cursor_x + self.word_spacing + self.font:getWidth(word)
        i = i + 1
    end

    -- Draw input buffer
    cursor_y = word_y + self.font:getHeight() + self.line_spacing
    cursor_x = word_x
    for i = 1, #self.input_buffer do
        local c = string.sub(self.input_buffer, i, i)
        if c == string.sub(self.target_word, i, i) then
            love.graphics.print({self.correct_color, c}, self.font, cursor_x, cursor_y)
        else
            love.graphics.print({self.invalid_color, c}, self.font, cursor_x, cursor_y)
        end
        cursor_x = cursor_x + self.font:getWidth(c)
    end
end

function practice:keypressed(key)
    if key == "lshift" then
        self.lshift_count = self.lshift_count + 1
        if self.lshift_count == 3 then
            self.lshift_count = 0
            self:load()
        end
    else
        self.started = true
        self.lshift_count = 0
    end
    if key == "backspace" then
        self.input_buffer = string.sub(self.input_buffer, 1, #self.input_buffer - 1)
    end
end

function practice:textinput(text)
    if self.done or text == " " then return end
    self.started = true
    self.input_buffer = self.input_buffer .. text
    if self.input_buffer == self.test_words[self.word_index] then
        self.left_shift = self.left_shift + self.font:getWidth(self.test_words[self.word_index]) + self.word_spacing
        self.word_index = self.word_index + 1
        self.input_buffer = ""
        self.words_typed = self.words_typed + 1

        if self.word_index == #self.test_words then
            self:save_score(self.exercise_name, self:wpm(), self:accuracy())
            self.done = true
        end
    elseif self:partial_match(self.input_buffer, self.test_words[self.word_index]) then
        -- Ignore
    elseif self.time_until_delete >= 0 then
        self.time_until_delete = .4
    else
        self.time_until_delete = .4
        self.mistakes = self.mistakes + 1
    end
end

function practice:focus(f)
    self.focused = f
end

function practice:string_split(str)
    local t = {}
    for k in string.gmatch(str, "[^%s]+") do
        t[#t+1] = k
    end
    return t
end

function practice:shuffle_list(list)
    for i = #list, 2, -1 do
        local j = love.math.random(i)
        list[i], list[j] = list[j], list[i]
    end
end

function practice:partial_match(str1, str2)
    for i = 1,math.min(#str1, #str2) do
        if string.sub(str1, i, i) ~= string.sub(str2, i, i) then
            return false
        end
    end
    return true
end

function practice:format_number(num)
    return string.format("%.1f", num)
end

function practice:save_score(exercise_name, wpm, accuracy)
    local score_filename = exercise_name .. "_score.txt"
    local score_row = os.date("%m/%d %H:%M:%S ") .. wpm .. " " .. accuracy .. "\n"
    local f = love.filesystem.newFile(score_filename, "a")
    f:write(score_row)
    f:close()
end

return practice