require 'rubygems'
require 'bundler/setup'

require 'dicom'
include DICOM
require_relative 'dicom-sr-constrants.rb'
require 'yaml'
require 'rmagick'
require 'ostruct'
require 'open-uri'
require 'tempfile'

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

# get dcm
node = DClient.new(settings.pacs_ip, settings.pacs_port, { host_ae: settings.pacs_ae })
images = node.find_images({"0008,0050" => acc_no, "0008,0060" => "OT"})
if images.empty?
  p "No OCR object for accession number: #{acc_no}"
  exit
end

# get image from WADO
image = images.first
wado_url = "http://#{settings.wado_ip}:#{settings.wado_port}/#{settings.wado_path}/?" +
           "&requestType=WADO" +
           "&studyUID=" + image["0020,000D"] +
           "&seriesUID=" + image["0020,000E"] +
           "&objectUID=" + image["0008,0018"]

p wado_url
dcm = nil
begin
  open(wado_url) {|uri|
    #f = Tempfile.new('ocr_bd')
    #dcm_file = uri.read
    #dcm = DObject.parse(dcm_file)
    #dcm.write(f.path)

    img = Magick::Image.read(uri.path).first

    # crop
    fc = Tempfile.new(['ocr_bd_crop', '.tif'])
    img.crop(476, 203, 152, 16).scale(2).write(fc.path)
    #p fc.path
    # ocr
    txt_f = Tempfile.new('ocr_bd_txt')
    `tesseract "#{fc.path}" "#{txt_f.path}" 2>/dev/null`
    #p txt_f.path
    ocr_result = File.read(txt_f.path + ".txt").to_s
    # manipulate text
    mp_age = nil
    ocr_result.match(/Menopause Age: ([\w\d]+)/) do |m|
      mp_age = m[1]
      # correct "so" to 50
      mp_age = "50" if mp_age == "so"
    end

    txt_f.unlink
    fc.unlink
    #f.unlink

    p "#{mp_age.to_s} ||| #{ocr_result}"
  }
rescue OpenURI::HTTPError => error
  response = error.io
  return response.status, nil
end
