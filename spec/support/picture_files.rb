require "zlib"

# Builds unusual picture files at run time, so they never need to live in the repository.
module PictureFiles
  # A valid PNG header declaring the given dimensions, without real pixel data: a decompression bomb in a few bytes.
  def png_bomb(width, height)
    chunk = lambda do |type, data|
      [ data.bytesize ].pack("N") + type + data + [ Zlib.crc32(type + data) ].pack("N")
    end
    bytes = "\x89PNG\r\n\x1a\n".b +
      chunk.call("IHDR", [ width, height, 8, 2, 0, 0, 0 ].pack("NNCCCCC")) +
      chunk.call("IDAT", Zlib::Deflate.deflate("\x00")) +
      chunk.call("IEND", "")
    uploaded_file(bytes, "bomb.png")
  end

  # The beginning of a real JPEG: right magic bytes and header, unreadable pixel data.
  def truncated_jpeg
    uploaded_file(file_fixture("plant_with_gps.jpg").binread.first(400), "truncated.jpg")
  end

  private

  def uploaded_file(bytes, name)
    file = Tempfile.new([ "picture", File.extname(name) ], binmode: true)
    file.write(bytes)
    file.rewind
    Rack::Test::UploadedFile.new(file.path, original_filename: name)
  end
end

RSpec.configure do |config|
  config.include PictureFiles
end
