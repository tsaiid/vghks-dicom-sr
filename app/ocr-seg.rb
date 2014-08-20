require 'rtesseract'
require 'RMagick'

class RTesseract
  # Class to read an image from specified areas
  class MyMixed < Mixed
    def labeled_area(x, y, width, height, label)
      @value = ''
      @areas << { :x => x,  :y => y, :width => width, :height => height, :label => label }
    end

    # Convert parts of image to string
    def convert_with_label
      @value = {}
      @areas.each_with_object(RTesseract.new(@source.to_s, @options.dup)) do |area, image|
        image.crop!(area[:x], area[:y], area[:width], area[:height])
        @value[area[:label]] = image.to_s.gsub(/\n+/, '')
      end
    rescue => error
      raise RTesseract::ConversionError.new(error)
    end

    # Output with label
    def to_s_with_label
      if @source.file?
        convert_with_label
        @value
      else
        fail RTesseract::ImageNotSelectedError.new(@source)
      end
    end
  end
end

def ocr_seg(path)
  # crop image to small
  img = Magick::Image.read(path).first
  areas = [
    { x: 470, y: 870, w: 68, h: 41, l: "RtABI"},
    { x: 730, y: 870, w: 68, h: 41, l: "LtABI"},

    { x: 690, y: 1068, w: 57, h: 25, l: "RtBrachial" },
    { x: 755, y: 1068, w: 57, h: 25, l: "LtBrachial" },

    { x: 690, y: 1128, w: 57, h: 25, l: "RtUpperThigh" },
    { x: 755, y: 1128, w: 57, h: 25, l: "LtUpperThigh" },

    { x: 690, y: 1187, w: 57, h: 25, l: "RtLowerThigh" },
    { x: 755, y: 1187, w: 57, h: 25, l: "LtLowerThigh" },

    { x: 690, y: 1245, w: 57, h: 25, l: "RtCalf" },
    { x: 755, y: 1245, w: 57, h: 25, l: "LtCalf" },

    { x: 690, y: 1305, w: 57, h: 25, l: "RtAnkle" },
    { x: 755, y: 1305, w: 57, h: 25, l: "LtAnkle" }
  ]

  ocr_result = {}

  areas.each do |area|
    f = Tempfile.new([area[:l], ".tif"])
    img.crop(area[:x], area[:y], area[:w], area[:h]).write(f.path)
    txt_f = Tempfile.new(area[:l])
    `tesseract "#{f.path}" "#{txt_f.path}" 2>/dev/null`
    ocr_result[area[:l]] = File.read(txt_f.path + ".txt").to_s
    f.unlink
    txt_f.unlink
  end

  ocr_result.each do |k, v|
    ocr_result[k] = (v.to_i > 2) ? v.to_i.to_s : ("%.2f" % v.to_f) if v.length > 0
  end
end
