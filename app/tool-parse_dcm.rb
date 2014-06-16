require 'dicom'
include DICOM
require './dicom-sr-philips.rb'
require './dicom-sr-ge.rb'
require './dicom-sr-ge-r3.1.2.rb'
require './dicom-sr-constrants.rb'

DICOM.logger.level = Logger::ERROR

# for fix ruby-dicom gem 0.9.5
require 'json'
require 'yaml'

def parse_dcm(path)
  dcm = DObject.read(path)

  if dcm[Mo].value == "SR"
    manufacturer = dcm[Ma].value

    p path

    case manufacturer
    when "Philips Medical Systems"
      fi_item = pms_find_findings_item(dcm)
      ud_item = pms_find_user_defined_concepts_item(dcm)
      p pms_get_measurements(fi_item)
      p pms_get_user_defined_measurements_calculations(ud_item)
    when "GE Medical Systems"
      p gms_get_all_measurements(dcm[CS])
    when "GE Healthcare"
      p gh_get_all_measurements(dcm[CS])
    else
      p "#{manufacturer} is not supported yet."
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