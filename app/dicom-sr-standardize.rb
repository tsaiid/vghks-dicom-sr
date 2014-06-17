require 'ruby-units'

def standardize_site(site)
  return "kidney" if ["Kidney", "Renal L", "Lt Renal L", "Rt Renal L"].include? site
  return "spleen" if ["Spleen", "Splenic L"].include? site
  return "CBD" if ["CBD", "Bileduct"].include? site
  return "Ovary L" if ["Lt Ovary L", "Rt Ovary L"].include? site
  return "Ovary W" if ["Lt Ovary W", "Rt Ovary W"].include? site
  return "Ovary H" if ["Lt Ovary H", "Rt Ovary H"].include? site
  return "Ovary Vol" if ["Lt Ovary Vol", "Rt Ovary Vol"].include? site
  site
end

def standardize_side(side)
  return "left" if ["Left", "Lt"].include? side
  return "right" if ["Right", "Rt"].include? side
  side
end

def define_units
  Unit.define("m3") do |m3|
    m3.definition   = Unit("1000 l")   # anything that results in a Unit object
    m3.aliases      = ["cubic meter", "m3"]                   # array of synonyms for the unit
    m3.display_name = "m3"                        # How unit is displayed when output
  end

  # mm3 is pre-defined, but seems wrong???
  Unit.define("mm3") do |mm3|
    mm3.definition   = Unit("0.001 ml")   # anything that results in a Unit object
    mm3.aliases      = ["cubic millimeter", "mm3"]                   # array of synonyms for the unit
    mm3.display_name = "mm3"                        # How unit is displayed when output
  end
end

def preferred_unit(site, ori_unit)
  my_preferred_unit = {
    "kidney" => "cm",
    "spleen" => "cm",
    "CBD" => "mm",
    "Prostate L" => "cm",
    "Prostate H" => "cm",
    "Prostate W" => "cm",
    "Prostate Vol" => "ml",
    "Ovary L" => "cm",
    "Ovary W" => "cm",
    "Ovary H" => "cm",
    "Ovary Vol" => "ml",
    "Endometrium" => "mm",
    "Uterus L" => "cm",
    "Uterus H" => "cm",
    "Uterus W" => "cm",
    "Uterus Vol" => "ml"
  }

  my_preferred_unit[site].nil? ? ori_unit : my_preferred_unit[site]
end

def standardize_value(site, value, unit)
  # define units
  # m3 is not supported by ruby-units by default
  define_units

  # strange hack, ruby-units conversion sometimes results in rational scalar?!
  # follow this issue: https://github.com/olbrich/ruby-units/issues/102
  if Unit(value + unit).units.empty?
    {value: value, unit: unit}
  else
    #p "site: #{site}; value: #{value}; unit: #{unit}"
    converted_value = Unit(value + unit).convert_to(preferred_unit(site, unit)).round(1)
    converted_value.scalar.to_f.to_s + " " + preferred_unit(site, unit)
  end
end

def standardize_result(results)
  standardized_result = {}
  if results
    results.each do |r|
      #p "site: #{r[:site]}; side: #{r[:side]}; value: #{r[:value]}; unit: #{r[:unit]}"

      std_site = standardize_site(r[:site])
      #std_site = r[:site]
      std_side = standardize_side(r[:side])
      if std_side.nil?
        standardized_result[std_site] = standardize_value(std_site, r[:value], r[:unit])
      else
        if standardized_result[std_site].nil?
          standardized_result[std_site] = { std_side => standardize_value(std_site, r[:value], r[:unit]) }
        else
          standardized_result[std_site][std_side] = standardize_value(std_site, r[:value], r[:unit])
        end
        #value: r[:value]+r[:unit]
      end
    end
    standardized_result[:debug] = results
  end
  return standardized_result.empty? ? nil : standardized_result
end
