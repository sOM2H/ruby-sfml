require "sfml/version"

module SFML
  # Root of the ruby-sfml exception hierarchy. Every CSFML-side
  # failure surfaces as something inheriting from `SFML::Error`, so
  # `rescue SFML::Error` is the catch-all.
  #
  # Subclasses let callers target a domain:
  #
  #   rescue SFML::LoadError       # file / decode / GPU upload failed
  #   rescue SFML::AudioError      # OpenAL / capture / playback issues
  #   rescue SFML::NetworkError    # socket / packet framing
  #   rescue SFML::ShaderError     # GLSL compile / uniform / link
  #   rescue SFML::GraphicsError   # render-side issues other than load
  #   rescue SFML::WindowError     # window/context creation / events
  class Error < StandardError; end

  # An asset failed to load — file missing, format unsupported, GPU
  # upload rejected, etc. Raised by `Texture.load` / `Font.load` /
  # `Image.load` / `SoundBuffer.load` / `Music.load` and their
  # `from_memory` / `from_stream` siblings.
  class LoadError < Error; end

  # An audio operation failed at the OpenAL or CSFML capture layer —
  # `SoundRecorder#start` couldn't open the device, channel-map was
  # rejected, etc.
  class AudioError < Error; end

  # A network operation failed — socket couldn't open, packet framing
  # was malformed, HTTP/FTP transport rejected the request.
  class NetworkError < Error; end

  # A shader couldn't compile or link, or an unknown uniform name was
  # set. CSFML logs the compiler error to stderr; this exception just
  # signals the failure.
  class ShaderError < Error; end

  # Generic graphics-side failure that isn't a load. Render-texture
  # allocation, framebuffer setup, view/scissor math, etc.
  class GraphicsError < Error; end

  # Window or GL context couldn't be created, or a windowing primitive
  # (cursor, clipboard) failed.
  class WindowError < Error; end
end

# Tame process-exit teardown so CSFML doesn't crash.
#
# Two things race during a normal Ruby exit:
#
# 1. ObjectSpace finalizers run in non-deterministic order. CSFML's
#    GL-bound resources (RenderWindow's GL context, Font glyph atlases,
#    View copies) freed in the wrong sequence segfault inside the
#    SFML/GL stack. Setting autorelease = false on every live
#    FFI::AutoPointer skips the destruction; the OS reclaims memory
#    anyway, so this costs nothing.
#
# 2. SFML's audio thread is still pumping samples while Ruby starts to
#    tear the interpreter down. If a `Sound` or `Music` is mid-loop,
#    OpenAL is reading buffers we're about to free → segfault inside
#    libopenal. Stopping every live source first quiets the audio
#    thread before anything starts disappearing.
#
# Unreferenced objects still get cleaned up at runtime via the normal
# GC cycle; we only neuter the *teardown-time* pass.
at_exit do
  # 1. Capture the desired exit status before we tamper with anything.
  status =
    if    $!.is_a?(SystemExit) then $!.status
    elsif $!.nil?              then 0
    else                            1
    end

  # 2. If we're exiting because of an unhandled exception, print it
  #    ourselves — `exit!` below skips Ruby's terminal exception
  #    reporter, so without this the user sees a silent exit instead
  #    of the stack trace they'd normally get.
  if $! && !$!.is_a?(SystemExit)
    err = $!
    warn "#{err.backtrace.first}: #{err.message} (#{err.class})"
    err.backtrace.drop(1).each { |line| warn "\tfrom #{line}" }
  end

  # 3. Quiet the audio thread before anything else — OpenAL holds onto
  #    sample buffers and crashes if Ruby starts freeing them while
  #    a Sound/Music is mid-loop.
  ObjectSpace.each_object(SFML::Sound) { |s| s.stop rescue nil } if defined?(SFML::Sound)
  ObjectSpace.each_object(SFML::Music) { |m| m.stop rescue nil } if defined?(SFML::Music)
  # SoundStream isn't stopped from this hook on purpose — by the time
  # at_exit runs, finalizer ordering can have already destroyed
  # the underlying CSFML stream, and CSFML asserts on a stale handle.
  # Either explicitly #stop your SoundStream before exit, or rely on
  # exit!() below to skip the audio thread's natural teardown.

  # 4. Bypass Ruby's natural finalizer pass entirely. Process memory is
  #    about to be reclaimed by the kernel anyway, and Ruby's
  #    non-deterministic destruction order races with CSFML's GL/audio
  #    internals — segfaulting inside libopenal/libGL is the typical
  #    failure mode. exit! kills the interpreter cleanly via _exit(2).
  #
  # Caveat: any user `at_exit` hook registered *before* `require "sfml"`
  # won't run. Hooks registered after the require run first (LIFO),
  # then our hook, so the common case is unaffected.
  exit!(status)
end

require "sfml/c"
require "sfml/system/time"
require "sfml/system/clock"
require "sfml/system/vector2"
require "sfml/system/vector3"
require "sfml/system/rect"
require "sfml/system/input_stream"
require "sfml/window/keyboard"
require "sfml/window/mouse"
require "sfml/window/joystick"
require "sfml/window/touch"
require "sfml/window/sensor"
require "sfml/window/cursor"
require "sfml/window/clipboard"
require "sfml/window/video_mode"
require "sfml/window/event"
require "sfml/window/context_settings"
require "sfml/window/window"
require "sfml/window/context"
require "sfml/graphics/color"
require "sfml/graphics/transformable"
require "sfml/graphics/shape_inspectable"
require "sfml/graphics/transformable_object"
require "sfml/graphics/image"
require "sfml/graphics/texture"
require "sfml/graphics/sprite"
require "sfml/graphics/circle_shape"
require "sfml/graphics/rectangle_shape"
require "sfml/graphics/convex_shape"
require "sfml/graphics/shape"
require "sfml/graphics/vertex"
require "sfml/graphics/vertex_array"
require "sfml/graphics/vertex_buffer"
require "sfml/graphics/font"
require "sfml/graphics/text"
require "sfml/graphics/view"
require "sfml/graphics/blend_mode"
require "sfml/graphics/stencil_mode"
require "sfml/graphics/shader"
require "sfml/graphics/transform"
require "sfml/graphics/render_states"
require "sfml/graphics/render_target"
require "sfml/graphics/render_window"
require "sfml/graphics/render_texture"
require "sfml/graphics/texture_atlas"
require "sfml/graphics/sprite_sheet"
require "sfml/graphics/animation"
require "sfml/graphics/particle_system"
require "sfml/audio/internal"
require "sfml/audio/sound_buffer"
require "sfml/audio/sound_cone"
require "sfml/audio/sound"
require "sfml/audio/music"
require "sfml/audio/listener"
require "sfml/audio/sound_recorder"
require "sfml/audio/sound_buffer_recorder"
require "sfml/audio/sound_stream"
require "sfml/network/ip_address"
require "sfml/network/packet"
require "sfml/network/tcp_socket"
require "sfml/network/tcp_listener"
require "sfml/network/udp_socket"
require "sfml/network/socket_selector"
require "sfml/network/http"
require "sfml/network/ftp"
require "sfml/assets"
require "sfml/keybindings"
require "sfml/input_actions"
require "sfml/scene"
require "sfml/app"
