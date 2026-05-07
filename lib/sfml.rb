require "sfml/version"

module SFML
  class Error < StandardError; end
  class LoadError < Error; end
end

# Skip CSFML destructor calls during process exit.
#
# Ruby runs ObjectSpace finalizers in non-deterministic order during
# teardown. CSFML resources are deeply intertwined — RenderWindow holds
# a GL context, Font holds glyph atlases bound to that context, Text and
# Sprite reference Font and Texture, View instances are independent but
# many. When the natural teardown destroys them in the wrong order,
# CSFML/GL segfaults. The exact sequence is the user's problem space:
# any non-trivial example using View + Text + map_pixel_to_coords can
# trip it.
#
# The OS reclaims process memory on exit anyway, so dropping CSFML
# destructors here costs nothing in practice — the gain is no late-exit
# crash. Unreferenced objects still get cleaned up at runtime via the
# normal GC cycle; we only neuter the *teardown-time* finalizer pass.
at_exit do
  GC.start                                     # release transient state cleanly first
  ObjectSpace.each_object(FFI::AutoPointer) do |pointer|
    pointer.autorelease = false rescue nil
  end
end

require "sfml/c"
require "sfml/system/time"
require "sfml/system/clock"
require "sfml/system/vector2"
require "sfml/system/vector3"
require "sfml/system/rect"
require "sfml/window/keyboard"
require "sfml/window/mouse"
require "sfml/window/joystick"
require "sfml/window/video_mode"
require "sfml/window/event"
require "sfml/graphics/color"
require "sfml/graphics/transformable"
require "sfml/graphics/image"
require "sfml/graphics/texture"
require "sfml/graphics/sprite"
require "sfml/graphics/circle_shape"
require "sfml/graphics/rectangle_shape"
require "sfml/graphics/convex_shape"
require "sfml/graphics/vertex"
require "sfml/graphics/vertex_array"
require "sfml/graphics/font"
require "sfml/graphics/text"
require "sfml/graphics/view"
require "sfml/graphics/blend_mode"
require "sfml/graphics/shader"
require "sfml/graphics/render_states"
require "sfml/graphics/render_target"
require "sfml/graphics/render_window"
require "sfml/graphics/render_texture"
require "sfml/audio/sound_buffer"
require "sfml/audio/sound"
require "sfml/audio/music"
require "sfml/assets"
require "sfml/game"
