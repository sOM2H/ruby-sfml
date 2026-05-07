module SFML
  # The system clipboard. UTF-8 in, UTF-8 out — even when the OS stores
  # it as wide chars, we go through CSFML's `*UnicodeString` variants
  # and convert in Ruby so non-ASCII text round-trips losslessly.
  #
  #   SFML::Clipboard.text             #=> "whatever was last copied"
  #   SFML::Clipboard.text = "пример"
  #
  # Useful inside text-input UIs (Ctrl+C / Ctrl+V handlers) and for
  # quick "copy that error message" buttons in tools.
  module Clipboard
    module_function

    def text
      ptr = C::Window.sfClipboard_getUnicodeString
      return "" if ptr.null?

      codepoints = []
      offset = 0
      loop do
        cp = ptr.get_uint32(offset)
        break if cp.zero?
        codepoints << cp
        offset += 4
      end
      codepoints.pack("U*")
    end

    def text=(value)
      str = value.to_s.encode("UTF-8")
      cps = str.unpack("U*")
      buf = FFI::MemoryPointer.new(:uint32, cps.length + 1)
      buf.write_array_of_uint32(cps + [0])
      C::Window.sfClipboard_setUnicodeString(buf)
      str
    end
  end
end
