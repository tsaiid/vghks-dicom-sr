require 'dicom'
include DICOM
require_relative 'dicom-sr-constrants.rb'
require_relative 'dicom-sr-standardize.rb'
require_relative 'dicom-sr-ge-lunar.rb'
require 'yaml'
require 'ostruct'
require 'open-uri'
require 'tempfile'

DICOM.logger.level = Logger::ERROR

if ARGV.first.nil?
  p "need acc no."
  exit
end

acc_no = ARGV.first

# read config.yaml
# read config file
cfg = YAML.load_file('../config/config.yaml') # development env
settings = OpenStruct.new(
  :pacs_ip => cfg['pacs']['ip'],
  :pacs_port => cfg['pacs']['port'],
  :pacs_ae => cfg['pacs']['ae'],
  :wado_ip => cfg['wado']['ip'],
  :wado_port => cfg['wado']['port'],
  :wado_path => cfg['wado']['path']
)

# get dcms
node = DClient.new(settings.pacs_ip, settings.pacs_port, { host_ae: settings.pacs_ae })
images = node.find_images({"0008,0050" => acc_no, "0008,0060" => "SR"})
if images.empty?
  p "No SR object for accession number: #{acc_no}"
  exit
end

# for fix ruby-dicom gem 0.9.5
require 'json'
require 'yaml'

def parse_dcm(dcm)
  result = {}
  if dcm[Mo].value == "SR"
    manufacturer = dcm[Ma].value
    study = dcm[SD].value

#    p path
    p dcm.value(SD)

    case study
    when /^Bone densitometry/
      result = gelunar_all_measurements(dcm[CS])
      #p result
    else  # others
      p "Not bone density SR."
    end
  end

  result
end

merged_result = {}

images.each_with_index do |img, i|
  wado_url = "http://#{settings.wado_ip}:#{settings.wado_port}/#{settings.wado_path}/?" +
             "&requestType=WADO" +
             "&studyUID=" + img["0020,000D"] +
             "&seriesUID=" + img["0020,000E"] +
             "&objectUID=" + img["0008,0018"]

  #p wado_url
  dcm = nil
  begin
    open(wado_url) {|uri|
      dcm_file = uri.read
      dcm = DObject.parse(dcm_file)

      merged_result = merged_result.merge(parse_dcm(dcm))
      #p merged_result
    }
  rescue OpenURI::HTTPError => error
    response = error.io
    return response.status, nil
  end
end

p merged_result unless merged_result.empty?