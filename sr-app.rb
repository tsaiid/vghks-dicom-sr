require 'rubygems'
require 'bundler/setup'

require 'sinatra'
require 'yaml'
require 'json'
require 'tempfile'
require 'benchmark'
require_relative 'app/parse-dcm.rb'
require_relative 'app/ocr-dcm.rb'
require_relative 'app/get-dcm-by-acc.rb'
require_relative 'app/format-result.rb'

class DicomSR < Sinatra::Base
  configure do
    # read config file
    cfg = YAML.load_file('config/config.yaml')

    # set server info
    set :srvcfg => { 'pacs' => cfg['pacs'], 'wado' => cfg['wado'] }
  end

  get '/sr/:acc_no' do
    # "Hello #{params[:name]}!"
    acc_no = params[:acc_no]

    # Check if SR exists by AccNo
    status, dcms = get_dcm_by_acc_no(acc_no, "SR", 0, settings.srvcfg)

    # parse dcm
    dcm_parser_status, result = parse_dcm(dcms)

    # format result
    result_text = format_result(dcms, result)

    # merge status
    #status = dcm_parser_status unless dcm_parser_status.nil?

    content_type :text
    result_text
  end

  get '/sr/:acc_no/report' do
    response.headers['Access-Control-Allow-Origin'] = '*'

    # "Hello #{params[:name]}!"
    acc_no = params[:acc_no]

    # Check if SR exists by AccNo
    status, dcms = get_dcm_by_acc_no(acc_no, "SR", 0, settings.srvcfg)

    # parse dcm
    dcm_parser_status, result = parse_dcm(dcms)

    # format result
    result_text = format_result(dcms, result)

    # merge status
    #status = dcm_parser_status unless dcm_parser_status.nil?

    content_type :html
    { status: status, report: result_text }.to_json
  end

  get '/sr/:acc_no/json' do
    response.headers['Access-Control-Allow-Origin'] = '*'

    # "Hello #{params[:name]}!"
    acc_no = params[:acc_no]

    # Check if SR exists by AccNo
    status, dcms = get_dcm_by_acc_no(acc_no, "SR", 0, settings.srvcfg)

    # parse dcm
    dcm_parser_status, result = parse_dcm(dcms)

    # format result
    result_text = format_result(dcms, result)

    # merge status
    status = dcm_parser_status unless dcm_parser_status.nil?

    # strange behavior for AHK injected Ajax CORS request. The content type needs to be html rather than json ?!?!
    #content_type :json
    content_type :html
    { status: status, result: result }.to_json
  end

  get '/ocr/:acc_no/json' do
    response.headers['Access-Control-Allow-Origin'] = '*'

    # "Hello #{params[:name]}!"
    acc_no = params[:acc_no]

    # Check if DCM exists by AccNo
    status, dcm = get_dcm_by_acc_no(acc_no, "SC", 1, settings.srvcfg)

    # save temp file and convert by gdcm
    dcm_ocr_status = nil
    result = nil
    realtime = Benchmark.realtime do
      dcm = dcm.first
      if dcm
        fg = Tempfile.new('gdcm')
        fd = Tempfile.new('dcm')
        dcm.write(fd.path)
        `gdcmconv -w #{fd.path} #{fg.path}`
        fd.unlink

        # parse dcm
        dcm_ocr_status, result = ocr_dcm(fg.path)

        fg.unlink
      end
    end

    status[:realtime] = realtime

    # merge status
    status = dcm_ocr_status unless dcm_ocr_status.nil?

    # strange behavior for AHK injected Ajax CORS request. The content type needs to be html rather than json ?!?!
    #content_type :json
    content_type :html
    { status: status, result: result }.to_json
  end
end
