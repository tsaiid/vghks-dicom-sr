# encoding: UTF-8
require 'rtesseract'
require 'dicom'
include DICOM
require_relative 'dicom-sr-constrants.rb'

DICOM.logger.level = Logger::ERROR

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

def real_tag(ocr_text)
  case ocr_text
  when "V0"
    "VO"
  when "00"
    "OC"
  when "03"
    "O3"
  when "05"
    "O5"
  else
    ocr_text
  end
end

def ocr_spg(path)
  image = RTesseract.new(path) do |img|
    img = img.white_threshold(10)
    img = img.quantize(256,Magick::GRAYColorspace)
  end

  ocr_result = image.to_s.split(/\n/).keep_if {|v| v =~ /=/}

  result = {
    right: {},
    left: {}
  }
  ocr_result.each do |r|
    r.match(/(\w+)\s+=.+?([\d\.]{3,6}).+?([\d\.]{3,6})$/) do |m|
      result[:right][real_tag(m[1])] = m[2]
      result[:left][real_tag(m[1])] = m[3]
    end
  end
  result
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

def ocr_dcm(path)
  # check study description
  dcm = DObject.read(path)
  case dcm[SD].value
  when "SPG For vein"
    result = ocr_spg(path)
  when "Segmental pressures - 3or4 Cuff"
    result = ocr_seg(path)
  when "Spectrum analysis"
    # cannot do anything
  end

  p result
end

# if given a file, parse it only, else parse the whole directory
if ARGV.first.nil?
  # read file
  dcm_path = "/Users/tsaiid/Dropbox/dcm"

  Dir.glob(dcm_path + "/*.dcm").each do |file|
    p file
    ocr_dcm(file)
  end
else
  ocr_dcm(ARGV.first)
end