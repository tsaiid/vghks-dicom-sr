# encoding: UTF-8
require 'RMagick'
require 'dicom'
include DICOM
require 'tempfile'
require 'benchmark'
require_relative 'dicom-sr-constrants.rb'

DICOM.logger.level = Logger::ERROR

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

def tesseract_areas(img, areas)
  ocr_result = {}

  areas.each do |area|
    f = Tempfile.new([area[:l], ".tif"])
    rt_c = Benchmark.realtime do
      img.crop(area[:x], area[:y], area[:w], area[:h]).write(f.path)
    end
    txt_f = Tempfile.new([area[:l], ".txt"])
    rc_t = Benchmark.realtime do
      `tesseract "#{f.path}" "#{txt_f.path.gsub('.txt', '')}" 2>/dev/null`
    end
    ocr_result[area[:l]] = File.read(txt_f.path).to_s + " crop: #{rt_c} ocr: #{rc_t}"
    f.unlink
    txt_f.unlink
  end

  ocr_result
end

def ocr_spg(path)
  # crop image to small
  img = Magick::Image.read(path).first
  img = img.quantize(256, Magick::GRAYColorspace) # increase OCR accuracy

  areas = [
    { x: 658, y: 1162, w: 83, h: 25, l: "RtVO"},
    { x: 753, y: 1162, w: 83, h: 25, l: "LtVO"},

    { x: 674, y: 1192, w: 68, h: 24, l: "RtVC" },
    { x: 770, y: 1192, w: 68, h: 24, l: "LtVC" },

    { x: 674, y: 1224, w: 68, h: 24, l: "RtAF" },
    { x: 770, y: 1224, w: 68, h: 24, l: "LtAF" }
  ]

  ocr_result = tesseract_areas(img, areas)

  p ocr_result

  ocr_result.each do |k, v|
    ocr_result[k] = ("%.1f" % v.to_f) if v.length > 0
  end
end

def ocr_seg(path)
  # crop image to small
  img = Magick::Image.read(path).first
  img = img.quantize(256, Magick::GRAYColorspace) # increase OCR accuracy

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

  ocr_result = tesseract_areas(img, areas)

  p ocr_result

  ocr_result.each do |k, v|
    ocr_result[k] = (v.to_i > 2) ? v.to_i.to_s : ("%.2f" % v.to_f) if v.length > 0
  end

end

def ocr_dcm(path)
  # check study description
  dcm = DObject.read(path)
  result = nil
  realtime = Benchmark.realtime do
    case dcm[SD].value
    when "SPG For vein"
      result = ocr_spg(path)
    when "Segmental pressures - 3or4 Cuff"
      result = ocr_seg(path)
    when "Spectrum analysis"
      # cannot do anything
    end
  end

  result[:realtime] = realtime

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