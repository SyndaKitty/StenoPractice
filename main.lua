loader = require "loader"
practice = require "practice"

local current_scene = loader

function load_scene(scene, args)
    current_scene = scene
    scene:load(args)
end

function love.load()
    loader:load("exercises")
end

function love.update(dt)
    current_scene:update(dt)
end

function love.draw()
    current_scene:draw()
end

function love.keypressed(key, scancode, is_repeat)
    current_scene:keypressed(key, scancode, is_repeat)
end

function love.textinput(text)
    current_scene:textinput(text)
end

function love.focus(f)
    current_scene:focus(f)
end