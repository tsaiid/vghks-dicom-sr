require 'sinatra'
require 'dicom'
include DICOM
require 'yaml'
require 'json'
require 'open-uri'
require_relative 'dicom-sr-constrants.rb'
require_relative 'dicom-sr-philips.rb'
require_relative 'dicom-sr-ge.rb'
require_relative 'dicom-sr-ge-r3.1.2.rb'

configure do
  # read config file
  cfg = YAML.load_file('config.yaml')

  # set server info
  set :pacs_ip => cfg['pacs']['ip'], :pacs_port => cfg['pacs']['port'], :pacs_ae => cfg['pacs']['ae']
  set :wado_ip => cfg['wado']['ip'], :wado_port => cfg['wado']['port'], :wado_path => cfg['wado']['path']
end

get '/sr/:acc_no' do
  # "Hello #{params[:name]}!"
  acc_no = params[:acc_no]

  # Check if SR exists by AccNo
  status, dcm = get_sr_dcm_by_acc_no(acc_no)

  # parse dcm
  if dcm
    manufacturer = dcm[Ma].value

    case manufacturer
    when "Philips Medical Systems"
      fi_item = pms_find_findings_item(dcm)
      ud_item = pms_find_user_defined_concepts_item(dcm)
      result = pms_get_measurements(fi_item) + pms_get_user_defined_measurements_calculations(ud_item)
    when "GE Medical Systems"
      result = gms_get_all_measurements(dcm[CS])
    when "GE Healthcare"
      result = gh_get_all_measurements(dcm[CS])
    else
      status = { error: "1", message: "#{manufacturer} is not supported yet." }
    end
  end

  content_type :json
  { status: status, result: result }.to_json
end

def get_sr_dcm_by_acc_no(acc_no)
  node = DClient.new(settings.pacs_ip, settings.pacs_port, { host_ae: settings.pacs_ae })
  #study = node.find_studies({"0008,0050" => acc_no})
  #series = node.find_series({"0008,0050" => acc_no, "0008,0060" => "SR"})
  images = node.find_images({"0008,0050" => acc_no, "0008,0060" => "SR"})
  if images.empty?
    return {error: 1, message: "No SR object for accession number: #{acc_no}"}, nil
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

  return {error: 0, message: ""}, dcm
end

