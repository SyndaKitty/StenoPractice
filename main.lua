local practice = require "practice"

local current_scene = practice

function love.load()
    current_scene:load()
end

function love.update(dt)
    current_scene:update(dt)
end

function love.draw()
    current_scene:draw()
end

function love.keypressed(key)
    current_scene:keypressed(key)
end

function love.textinput(text)
    current_scene:textinput(text)
end

function love.focus(f)
    current_scene:focus(f)
end