require 'dicom'
include DICOM
require_relative 'dicom-sr-philips.rb'
require_relative 'dicom-sr-ge.rb'
require_relative 'dicom-sr-ge-r3.1.2.rb'
require_relative 'dicom-sr-constrants.rb'
require_relative 'dicom-sr-standardize.rb'
require_relative 'dicom-sr-ge-vascular.rb'
require_relative 'dicom-sr-ph-vascular.rb'
require_relative 'dicom-sr-ge-lunar.rb'

DICOM.logger.level = Logger::ERROR

# for fix ruby-dicom gem 0.9.5
require 'json'
require 'yaml'

def parse_dcm(path)
  dcm = DObject.read(path)

  if dcm[Mo].value == "SR"
    manufacturer = dcm[Ma].value
    study = dcm[SD].value

    p path
    p dcm.value(SD)

    case study
    when 'Sono & Doppler, Carotid art.-PCU' # vascular
      case manufacturer
      when "Philips Medical Systems"
        result = phv_get_all_measurements(dcm[CS])
      else
        result = gev_get_all_measurements(dcm[CS])
      end

      p result
    when /^Bone densitometry/
      result = gelunar_all_measurements(dcm[CS])

      p result
    else  # others
      case manufacturer
      when "Philips Medical Systems"
        result = pms_get_all_measurements(dcm)
      when "GE Medical Systems"
        result = gms_get_all_measurements(dcm[CS])
      when "GE Healthcare"
        result = gh_get_all_measurements(dcm[CS])
      else
        result = "#{manufacturer} is not supported yet."
      end

      p standardize_result(result)
    end
  end
end

# if given a file, parse it only, else parse the whole directory
if ARGV.first.nil?
  # read file
  dcm_path = "/Users/tsaiid/Dropbox/dcm"

  Dir.glob(dcm_path + "/*.dcm").each do |file|
    parse_dcm(file)
  end
else
  parse_dcm(ARGV.first)
end