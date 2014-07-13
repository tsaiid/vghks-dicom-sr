require 'rtesseract'

def real_tag(ocr_text)
  case ocr_text
  when "V0"
    "VO"
  when "00"
    "OC"
  when "03"
    "O3"
  when "05"
    "O5"
  else
    ocr_text
  end
end

def ocr_spg(path)
  image = RTesseract.new(path) do |img|
    img = img.white_threshold(10)
    img = img.quantize(256,Magick::GRAYColorspace)
  end

  ocr_result = image.to_s.split(/\n/).keep_if {|v| v =~ /=/}

  result = {
    right: {},
    left: {}
  }
  has_result = false
  ocr_result.each do |r|
    r.match(/(\w+)\s+=.+?([\d\.]{3,6}).+?([\d\.]{3,6})$/) do |m|
      result[:right][real_tag(m[1])] = m[2]
      result[:left][real_tag(m[1])] = m[3]
      has_result = true
    end
  end
  has_result ? result : nil
end
