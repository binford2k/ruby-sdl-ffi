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


require 'ffi'

need 'typedpointer'


# A module to be used in place of FFI::Library. It acts mostly
# like FFI::Library, but with some nice extra features and
# conveniences to make life easier:
# 
# * attach_function accepts TypedPointers as return type,
#   in which case it wraps the return value of the bound function
#   in the TypedPointer's type.
# 
module NiceLibrary

  def self.extend_object( klass )
    klass.extend FFI::Library
    super
  end


  # A Hash of { os_regex => path_templates } pairs describing
  # where to look for libraries on each operating system.
  # 
  # * os_regex is a regular expression that matches FFI::Platform::OS
  #   for the operating system(s) that the path templates are for.
  # 
  # * path_templates is be an Array of one or more strings
  #   describing a template for where a library might be found on this
  #   OS. The string [LIB] will be replaced with the library name.
  #   So "/usr/lib/lib[LIB].so" becomes e.g. "/usr/lib/libSDL_ttf.so".
  # 
  LIBRARY_PATHS = {

    /linux|bsd/  => [ "/usr/local/lib/lib[LIB].so",
                      "/usr/lib/lib[LIB].so",
                      "[LIB]" ],

    /darwin/     => [ "/usr/local/lib/lib[LIB].dylib",
                      "/sw/lib/lib[LIB].dylib",
                      "/opt/local/lib/lib[LIB].dylib",
                      "~/Library/Frameworks/[LIB].framework/[LIB]",
                      "/Library/Frameworks/[LIB].framework/[LIB]",
                      "[LIB]" ],

    /win32/      => [ "C:\\windows\\system32\\[LIB].dll",
                      "C:\\windows\\system\\[LIB].dll",
                      "[LIB]" ]

  }


  # Try to find and load a library (e.g. "SDL_ttf") into an FFI
  # wrapper module (e.g. SDL::TTF). This method searches in
  # different locations depending on your OS. See LIBRARY_PATHS.
  # 
  # Returns the path to the library that was loaded.
  # 
  # Raises LoadError if it could not find or load the library.
  # 
  def load_library( lib_name, wrapper_module )

    os = FFI::Platform::OS

    # Find the regex that matches our OS.
    os_match = LIBRARY_PATHS.keys.find{ |regex|  regex =~ os }

    # Oops, none of the regexs matched our OS.
    if os_match.nil?
      raise( LoadError, "Your OS (#{os}) is not supported yet.\n" +
             "Please report this and help us support more platforms." )
    end

    # Fetch the paths for the matching OS.
    paths = LIBRARY_PATHS[os_match]

    # Fill in for [LIB] and expand the paths.
    paths = paths.collect { |path|
      File.expand_path( path.gsub("[LIB]", lib_name) )
    }

    # Try loading each path until one works.
    loaded = paths.find { |path| 
      begin
        wrapper_module.module_eval {
          ffi_lib path
        }
      rescue LoadError
        false
      else
        true
      end
    }

    # Oops, none of them worked.
    if loaded.nil?
      raise( LoadError, "Could not load library #{lib_name}." )
    else
      # Return the one that did work
      return loaded
    end
  end


  def attach_function( methname, arg1, arg2, arg3=nil )

    # To match the normal attach_function's weird syntax.
    # The arguments can be either:
    # 
    # 1. methname, args, retrn_type  (funcname = methname)
    # 2. methname, funcname, args, retrn_type
    # 
    funcname, args, retrn_type = if arg1.kind_of?(Array)
                                    [methname, arg1, arg2]
                                  else
                                    [arg1, arg2, arg3]
                                  end

    unless retrn_type.kind_of? TypedPointer
      # Normal FFI::Library.attach_function behavior.
      super
    else

      # Create the raw FFI binding, which returns a pointer.
      # We call it __methname because it's not meant to be called
      # by users. We also make it private below.
      # 
      super( "__#{methname}".to_sym, funcname, args, :pointer )


      # CAUTION: Metaclass hackery ahead! Handle with care!

      metaklass = class << self; self; end
      metaklass.instance_eval {

        # Create the nice method, which calls __methname and wraps the
        # return value (a pointer) the appropriate class using
        # TypedPointer#wrap. This is the one that users should call,
        # so we don't prepend the name with _'s.
        # 
        define_method( methname ) do |*args|
          retrn_type.wrap( send("__#{methname}".to_sym, *args) )
        end

        # __methname is private.
        private "__#{methname}".to_sym

      }

    end

  end
end
