require 'dicom'
include DICOM
require_relative 'dicom-sr-constrants.rb'
require 'yaml'
require 'ostruct'
require 'open-uri'

if ARGV.first.nil?
  p "need acc no."
  exit
end

acc_no = ARGV.first

# read config.yaml
# read config file
cfg = YAML.load_file('config.yaml') # development env
settings = OpenStruct.new(
  :pacs_ip => cfg['pacs']['ip'],
  :pacs_port => cfg['pacs']['port'],
  :pacs_ae => cfg['pacs']['ae'],
  :wado_ip => cfg['wado']['ip'],
  :wado_port => cfg['wado']['port'],
  :wado_path => cfg['wado']['path']
)

# get dcm
node = DClient.new(settings.pacs_ip, settings.pacs_port, { host_ae: settings.pacs_ae })
#study = node.find_studies({"0008,0050" => acc_no})
#series = node.find_series({"0008,0050" => acc_no, "0008,0060" => "SR"})
images = node.find_images({"0008,0050" => acc_no, "0008,0060" => "SR"})
if images.empty?
  p "No SR object for accession number: #{acc_no}"
  exit
end

# get image from WADO
image = images.first
wado_url = "http://#{settings.wado_ip}:#{settings.wado_port}/#{settings.wado_path}/?" +
           "&requestType=WADO" +
           "&studyUID=" + image["0020,000D"] +
           "&seriesUID=" + image["0020,000E"] +
           "&objectUID=" + image["0008,0018"]

#p wado_url
dcm = nil
begin
  open(wado_url) {|f|
    dcm = DObject.parse(f.read)
  }
rescue OpenURI::HTTPError => error
  response = error.io
  return response.status, nil
end

if dcm
  # convert to yaml
  fname = dcm.value(AN) + ".yaml"
  File.open(fname, "w") do |f|
    f.write dcm.to_yaml
  end
end