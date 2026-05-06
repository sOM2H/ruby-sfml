require "sfml/version"

module SFML
  class Error < StandardError; end
  class LoadError < Error; end
end

require "sfml/c"
require "sfml/system/time"
require "sfml/system/clock"
require "sfml/system/vector2"
require "sfml/system/vector3"
require "sfml/system/rect"
require "sfml/window/keyboard"
require "sfml/window/mouse"
require "sfml/window/video_mode"
require "sfml/window/event"
require "sfml/graphics/color"
require "sfml/graphics/transformable"
require "sfml/graphics/texture"
require "sfml/graphics/sprite"
require "sfml/graphics/circle_shape"
require "sfml/graphics/rectangle_shape"
require "sfml/graphics/font"
require "sfml/graphics/text"
require "sfml/graphics/render_window"
require "sfml/audio/sound_buffer"
require "sfml/audio/sound"
require "sfml/audio/music"
require "sfml/assets"
require "sfml/game"
