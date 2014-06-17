require 'ruby-units'

def standardize_site(site)
  return "kidney" if ["Kidney", "Renal L", "Lt Renal L", "Rt Renal L"].include? site
  return "spleen" if ["Spleen", "Splenic L"].include? site
  return "CBD" if ["CBD", "Bileduct"].include? site
  site
end

def standardize_side(side)
  return "left" if ["Left", "Lt"].include? side
  return "right" if ["Right", "Rt"].include? side
  side
end

def standardize_value(site, value, unit)
  preferred_unit_by_site = {
    "kidney" => "cm",
    "spleen" => "cm",
    "CBD" => "mm"
  }

  # strange hack, ruby-units conversion sometimes results in rational scalar?!
  # follow this issue: https://github.com/olbrich/ruby-units/issues/102
  converted_value = Unit(value + unit).convert_to(preferred_unit_by_site[site]).round(1)
  converted_value.scalar.to_f.to_s + " " + preferred_unit_by_site[site]
end

def standardize_result(results)
  standardized_result = []
  results.each do |r|
    std_site = standardize_site(r[:site])
    #std_site = r[:site]
    standardized_result << {
      site: std_site,
      side: standardize_side(r[:side]),
      value: standardize_value(std_site, r[:value], r[:unit])
      #value: r[:value]+r[:unit]
    }
  end
  return standardized_result.empty? ? nil : standardized_result
end
