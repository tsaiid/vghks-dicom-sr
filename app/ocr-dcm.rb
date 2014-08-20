require 'dicom'
include DICOM
require 'RMagick'
require_relative 'dicom-sr-constrants.rb'
require_relative 'ocr-spg.rb'
require_relative 'ocr-seg.rb'

def ocr_dcm(dcm_path)
  dcm = DObject.read(dcm_path)

  if dcm
    # determine the study description
    study = dcm[SD].value

    case study
    when "SPG For vein"
      result = ocr_spg(dcm_path)
    when "Segmental pressures - 3or4 Cuff"
      result = ocr_seg(dcm_path)
    else
      # including "Spectrum analysis"
      # cannot do anything
      status = { error: "1", message: "#{study} is not supported." }
    end

    if result.nil?
      status = {
        error: 1,
        message: "No recognizable data in this OT image."
      }
    end
  end

  return status, result
end

def tesseract_areas(img, areas)
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

  ocr_result
end
