require 'rtesseract'

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
  # very inefficient
  mix_block = RTesseract::MyMixed.new(path) do |image|
    image.labeled_area(470, 870, 68, 41, "RtABI")
    image.labeled_area(730, 870, 68, 41, "LtABI")

    image.labeled_area(690, 1068, 57, 25, "RtBrachial")
    image.labeled_area(755, 1068, 57, 25, "LtBrachial")

    image.labeled_area(690, 1128, 57, 25, "RtUpperThigh")
    image.labeled_area(755, 1128, 57, 25, "LtUpperThigh")

    image.labeled_area(690, 1187, 57, 25, "RtLowerThigh")
    image.labeled_area(755, 1187, 57, 25, "LtLowerThigh")

    image.labeled_area(690, 1245, 57, 25, "RtCalf")
    image.labeled_area(755, 1245, 57, 25, "LtCalf")

    image.labeled_area(690, 1305, 57, 25, "RtAnkle")
    image.labeled_area(755, 1305, 57, 25, "LtAnkle")
  end
  ocr_result = mix_block.to_s_with_label

  ocr_result.each do |k, v|
    ocr_result[k] = (v.to_i > 2) ? v.to_i.to_s : ("%.2f" % v.to_f) if v.length > 0
  end
end
