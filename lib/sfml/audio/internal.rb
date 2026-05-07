module SFML
  module Audio
    # Internal helpers shared between Sound, Music, and SoundStream.
    # Not part of the public API.
    module_function

    # Build an FFI::Function that adapts CSFML's effect-processor
    # signature (raw float buffers, in/out frame counts) to a Ruby
    # callable taking `(samples, channels)` and returning samples.
    #
    # Returns the FFI::Function — callers must keep a strong Ruby
    # reference to it for as long as it's installed (otherwise GC
    # collects the closure and the audio thread crashes).
    def _build_effect_processor(callable)
      FFI::Function.new(
        :void,
        [:pointer, :pointer, :pointer, :pointer, :uint32, :pointer],
      ) do |in_ptr, in_cnt_ptr, out_ptr, out_cnt_ptr, channels, _user|
        in_count  = in_cnt_ptr.read_uint32
        out_count = out_cnt_ptr.read_uint32

        written = 0
        if in_count > 0
          input = in_ptr.read_array_of_float(in_count * channels)
          output =
            begin
              callable.call(input, channels) || []
            rescue => e
              warn "ruby-sfml effect_processor raised: #{e.class}: #{e.message}"
              []
            end

          written = [output.length / channels, out_count].min
          out_ptr.write_array_of_float(output.first(written * channels)) if written.positive?
        end

        out_cnt_ptr.write_uint32(written)
      end
    end
  end
end
