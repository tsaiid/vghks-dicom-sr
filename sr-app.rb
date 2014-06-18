require 'rubygems'
require 'bundler/setup'

require 'sinatra'
require 'yaml'
require 'json'
require_relative 'app/parse-dcm.rb'
require_relative 'app/dicom-sr-get-dcm-by-acc.rb'

class DicomSR < Sinatra::Base

  configure do
    # read config file
    cfg = YAML.load_file('../../shared/config.yaml') # production env
    #cfg = YAML.load_file('app/config.yaml') # development env

    # set server info
    set :pacs_ip => cfg['pacs']['ip'], :pacs_port => cfg['pacs']['port'], :pacs_ae => cfg['pacs']['ae']
    set :wado_ip => cfg['wado']['ip'], :wado_port => cfg['wado']['port'], :wado_path => cfg['wado']['path']
  end

  get '/:acc_no' do
    # "Hello #{params[:name]}!"
    acc_no = params[:acc_no]

    # Check if SR exists by AccNo
    status, dcm = get_sr_dcm_by_acc_no(acc_no)

    # parse dcm
    dcm_parser_status, result = parse_dcm(dcm)

    content_type :json
    { status: status, result: result }.to_json
  end


end
