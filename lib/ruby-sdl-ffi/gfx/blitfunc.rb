#--
#
# This file is one part of:
#
# Ruby-SDL-FFI - Ruby-FFI bindings to SDL
#
# Copyright (c) 2009 John Croisant
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
#++


module SDL
  module Gfx

    optfunc  :BlitRGBA, "SDL_gfxBlitRGBA",
             [ :pointer, :pointer, :pointer, :pointer ], :int

    optfunc  :SetAlpha, "SDL_gfxSetAlpha", [ :pointer, :uint8 ], :int


    class BlitInfo < NiceFFI::Struct
      layout( :s_pixels, :pointer,
              :s_width,  :int,
              :s_height, :int,
              :s_skip,   :int,
              :d_pixels, :pointer,
              :d_width,  :int,
              :d_height, :int,
              :d_skip,   :int,
              :aux_data, :pointer,
              :src,      SDL::PixelFormat.typed_pointer,
              :table,    :pointer,
              :dst,      SDL::PixelFormat.typed_pointer )
    end

  end
end
