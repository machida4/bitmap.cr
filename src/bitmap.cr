# TODO: Write documentation for `Bitmap`
module Bitmap
  VERSION = "0.1.0"

  class Bitmap
    HEADER_SIZE = 54

    getter width, height, total_pixels, pixels

    def initialize(
      @header : Bytes,
      @width : UInt32,
      @height : UInt32,
      @byte_per_pixel : UInt8,
      @total_pixels : UInt32,
      @data : Bytes,
      @pixels : Array(Array(Pixel))
    )
    end


    def initialize(filepath : String)
      abort "missing file: #{filepath}" if !File.file?(filepath)
      image = File.new(filepath, "r")

      @header = Bytes.new(HEADER_SIZE)
      image.read(@header)

      validate_header!

      @width = IO::ByteFormat::LittleEndian.decode(UInt32, @header[18, 4])
      @height = IO::ByteFormat::LittleEndian.decode(UInt32, @header[22, 4])
      @total_pixels = @width * @height

      @byte_per_pixel = @header[28] // 8
      
      @data = Bytes.new(@total_pixels * @byte_per_pixel)
      image.read(@data)

      @pixels = Array.new(@width) { |i| Array(Pixel).new() }

      create_pixels_from_data()
    end

    def pixel(x : Int32, y : Int32)
      @pixels[x][y]
    end

    private def validate_header!
      if @header[0] != 0x42 || @header[1] != 0x4d
        abort "looks like it's not BMP file"
      end
      if IO::ByteFormat::LittleEndian.decode(UInt32, @header[46, 4]) != 0
        abort "Not supported a color palette yet."
      end
    end

    private def create_pixels_from_data
      sliced_data = @data.each_slice(@byte_per_pixel).to_a
      @height.times do |h|
        y = @height - h - 1 
        @width.times do |w|
          x = w
          pix_data = sliced_data.shift
          @pixels[x].unshift(Pixel.new(x: x, y: y, b: pix_data[0], g: pix_data[1], r: pix_data[2]))
        end
      end
    end
  end

  struct Pixel
    getter x, y
    property r, g, b

    def initialize(@x : UInt32, @y : UInt32, @r : UInt8, @g : UInt8, @b : UInt8)
    end

    def grayscale
      @r * 0.3 + @g * 0.59 + @b * 0.11
    end
  end
end
