require 'dicom'
include DICOM
require 'tempfile'
require_relative 'dicom-sr-constrants.rb'
require_relative 'ocr-spg.rb'
require_relative 'ocr-seg.rb'

def ocr_dcm(dcm)
  if dcm
    # save to a temp file
    f = Tempfile.new('ocr')

    # determine the study description
    study = dcm[SD].value

    case study
    when "SPG For vein"
      result = ocr_spg(f.path)
    when "Segmental pressures - 3or4 Cuff"
      result = ocr_seg(f.path)
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

    # unlink the temp file
    f.unlink
  end

  return status, result
end