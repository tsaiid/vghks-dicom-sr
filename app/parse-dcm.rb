require 'dicom'
include DICOM
require_relative 'dicom-sr-constrants.rb'
require_relative 'dicom-sr-philips.rb'
require_relative 'dicom-sr-ge.rb'
require_relative 'dicom-sr-ge-r3.1.2.rb'
require_relative 'dicom-sr-standardize.rb'
require_relative 'dicom-sr-ge-vascular.rb'
require_relative 'dicom-sr-ph-vascular.rb'
require_relative 'dicom-sr-ge-lunar.rb'

def parse_dcm(dcms)
  result = {}
  dcms.to_a.each do |dcm|
    manufacturer = dcm[Ma].value
    study = dcm[SD].value

    case study
    when 'Sono & Doppler, Carotid art.-PCU' # vascular
      case manufacturer
      when "Philips Medical Systems"
        result = phv_get_all_measurements(dcm[CS])
      else
        result = gev_get_all_measurements(dcm[CS])
      end
    when /^Bone densitometry/
      result = result.merge(gelunar_all_measurements(dcm[CS]))
    else  # others
      case manufacturer
      when "Philips Medical Systems"
        result = pms_get_all_measurements(dcm)
      when "GE Medical Systems"
        result = gms_get_all_measurements(dcm[CS])
      when "GE Healthcare"
        result = gh_get_all_measurements(dcm[CS])
      else
        status = { error: "1", message: "#{manufacturer} is not supported yet." }
      end

      result = standardize_result(result)
    end
  end

  if result.nil?
    status = {
      error: 1,
      message: "No fetchable data in this SR."
    }
  end

  return status, result
end