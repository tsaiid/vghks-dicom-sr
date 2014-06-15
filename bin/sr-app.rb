require 'sinatra'
require 'dicom'
include DICOM
require 'yaml'
require 'json'
require_relative 'dicom-sr-constrants.rb'

configure do
  # read config file
  cfg = YAML.load_file('config.yaml')

  # set server info
  set :pacs_ip => cfg['pacs_ip'], :pacs_port => cfg['pacs_port'], :pacs_ae => cfg['pacs_ae']
  set :wado_ip => cfg['wado_ip'], :wado_port => cfg['wado_port'], :wado_path => cfg['wado_path']
end

get '/sr/:acc_no' do
  # "Hello #{params[:name]}!"
  acc_no = params[:acc_no]

  # Check if SR exists by AccNo
  dcm, status = get_sr_dcm_by_acc_no(acc_no)

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
      status = { code: "1", message: "#{manufacturer} is not supported yet." }
    end
  end

  content_type :json
  { status: status, result: result }.to_json
end

def get_sr_dcm_by_acc_no(acc_no)
  node = DClient.new(settings.pacs_ip, settings.pacs_port, { host_ae: settings.pacs_ae })
  study = node.find_studies({"0008,0050" => acc_no})
  series = node.find_series({"0008,0061" => "SR\\US", "0020,000E" => study.value("0020,000E")})
  images = node.find_images({"0008,0018" => series.value("0008,0018")})

  # get image from WADO
  if images
    wado_url = "http://#{settings.wado_ip}:#{settings.wado_port}/#{settings.wado_path}/?"
             + "&requestType=WADO"
             + "&studyUID=" + images.value("")
             + "&seriesUID=" + images.value("")
             + "&objectUID=" + images.value("")

    begin
      open(wado_url) {|f|
        dcm = f.read
      }
    rescue OpenURI::HTTPError => error
      response = error.io
      return nil, response.status
    end
  end

  return dcm, nil
end

