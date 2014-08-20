def ocr_spg(path)
  # crop image to small
  img = Magick::Image.read(path).first
  img = img.quantize(256, Magick::GRAYColorspace) # increase OCR accuracy

  areas = [
    { x: 658, y: 1162, w: 83, h: 25, l: "RtVO"},
    { x: 753, y: 1162, w: 83, h: 25, l: "LtVO"},

    { x: 674, y: 1192, w: 68, h: 24, l: "RtVC" },
    { x: 770, y: 1192, w: 68, h: 24, l: "LtVC" },

    { x: 674, y: 1224, w: 68, h: 24, l: "RtAF" },
    { x: 770, y: 1224, w: 68, h: 24, l: "LtAF" }
  ]

  ocr_result = tesseract_areas(img, areas)

  ocr_result.each do |k, v|
    ocr_result[k] = ("%.1f" % v.to_f) if v.length > 0
  end
end
