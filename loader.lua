local loader = {
    font = love.graphics.newFont("Hack-Regular.ttf", 48),
    exercise_folder = "",
    exercises = nil,
    separator_width = 40,
    separator_height = 10,
    line_width = 0,
    selected_folder = 1,
    selected_exercise = 1,
    shift_folder = 0,
    shift_exercise = 0,
    folder_count = 0,
    folder_focused = true,
    tps = 144,
    spt = 1/144,
    accumulator = 0,
    line_height = 0,
    max_folder_width = 0,
    shift_line = 0,
}

function loader:load(exercise_folder)
    self.exercise_folder = exercise_folder
    self.exercises = self:gather_exercises(self.exercise_folder)

    local max_folder = 0
    local max_exercise = 0
    for _,v in ipairs(self.exercises) do
        max_folder = math.max(self.font:getWidth(v.name), max_folder)
        for _, exercise in ipairs(v.exercises) do
            max_exercise = math.max(self.font:getWidth(exercise), max_exercise)
        end
    end
    self.max_folder_width = max_folder
    self.line_width = max_exercise + max_exercise + self.separator_width
    self.line_height = self.separator_height + self.font:getHeight()
end

function loader:update(dt)
    self.accumulator = self.accumulator + dt
    while self.accumulator > self.spt do
        local prev = 0
        prev = self.shift_folder
        self.shift_folder = self.shift_folder * .9
        
        self.shift_line = self.shift_line + (prev - self.shift_folder) * .75

        prev = self.shift_exercise
        self.shift_exercise = self.shift_exercise * .9
        self.accumulator = self.accumulator - self.spt
        self.shift_line = self.shift_line + (prev - self.shift_exercise) * .5
    end
    self.shift_line = self.shift_line + dt * 10
end

function loader:draw()
    local left = love.graphics.getWidth() / 2 - self.line_width / 2
    local center_y = love.graphics.getHeight() / 2 - self.font:getHeight()

    for i,v in ipairs(self.exercises) do
        local offset = i - self.selected_folder
        local y = center_y + offset * self.line_height + self.shift_folder

        if self.folder_focused and i == self.selected_folder then
            love.graphics.setColor(1, 1, 1, 1)
        else
            love.graphics.setColor(.7, .7, .7, .7)
        end
        love.graphics.print(v.name, self.font, left, y)
    end

    love.graphics.setColor(.7, .7, .7, .7)
    love.graphics.setLineWidth(1)
    love.graphics.setLineStyle("smooth")
    local mid_line = left + self.max_folder_width + self.separator_width / 2
    local h = love.graphics.getHeight()
    local cy = self.shift_line % 40
    while cy < h do
        love.graphics.line(mid_line, cy, mid_line, cy + 20)
        cy = cy + 40
    end

    local lx = mid_line + self.separator_width / 2

    local folder = self.exercises[self.selected_folder]
    for i, v in ipairs(folder.exercises) do
        local offset = i - folder.selected
        local y = center_y + offset * self.line_height + self.shift_exercise

        if not self.folder_focused and i == folder.selected then
            love.graphics.setColor(1, 1, 1, 1)
        else
            love.graphics.setColor(.7, .7, .7, .7)
        end
        love.graphics.print(v, self.font, lx, y)
    end

end

function loader:keypressed(key, _, is_repeat)
    if is_repeat then return end
    local folder = self.exercises[self.selected_folder]
    if key == "down" then
        if self.folder_focused then
            local prev = self.selected_folder
            self.selected_folder = math.min(self.selected_folder + 1, #self.exercises)
            if prev == self.selected_folder then return end
            self.shift_folder = self.shift_folder + self.line_height
            self.shift_exercise = 0
        else
            local prev = folder.selected
            folder.selected = math.min(folder.selected + 1, #folder.exercises)
            if prev == folder.selected then return end
            self.shift_exercise = self.shift_exercise + self.line_height
        end
    elseif key == "up" then
        if self.folder_focused then
            local prev = self.selected_folder
            self.selected_folder = math.max(self.selected_folder - 1, 1)
            if prev == self.selected_folder then return end
            self.shift_folder = self.shift_folder - self.line_height
            self.shift_exercise = 0
        else
            local prev = folder.selected
            folder.selected = math.max(folder.selected - 1, 1)
            if prev == folder.selected then return end
            self.shift_exercise = self.shift_exercise - self.line_height
        end
    elseif key == "right" or key == "space" then
        if not self.folder_focused then
            local folder = self.exercises[self.selected_folder]
            local exercise_name = folder.exercises[folder.selected]
            local filepath = self.exercise_folder .. "/" .. folder.name .. "/" .. exercise_name .. ".txt"
            load_scene(practice, {filepath, exercise_name})
            return
        end
        self.folder_focused = false
    elseif key == "left" or key == "lshift" then
        self.folder_focused = true
    end
end

function loader:textinput(text)
    
end

function loader:focus(f)
    
end

function loader:gather_exercises(folder)
    local folders = {}
    local dirs = love.filesystem.getDirectoryItems(folder)
	
    for _,v in ipairs(dirs) do
		local filepath = folder.."/"..v
        
        local folder = {}
        folder.name = v
        local exercises = {}
        folder.exercises = exercises
        folder.selected = 1
        
        local files = love.filesystem.getDirectoryItems(filepath)
        for _,ex in ipairs(files) do
            if string.sub(ex, string.len(ex) - 3, string.len(ex)) == ".txt" then
                local truncated = string.sub(ex, 1, string.len(ex) - 4)
                exercises[#exercises+1] = truncated
            end
        end
        folders[#folders+1] = folder
	end
	return folders
end

return loader