# This script updates old survey ranks to the new rankings assuing them to be old and give Try More status unless GEPC=5.

UsGeo.all.each do |geo|

  
  if ((geo.zip.to_i >= 01001) && (geo.zip.to_i <= 06928)) then
    geo.region = "Northeast"
    geo.regionPrecode = "1"
    geo.division = "New England"
    geo.divisionPrecode = "1"
  else
  end
  
  if (geo.zip.to_i <= 00544) || ((geo.zip.to_i >= 07001) && (geo.zip.to_i <= 19612)) then
    geo.region = "Northeast"
    geo.regionPrecode = "1"
    geo.division = "Middle Atlantic"
    geo.divisionPrecode = "2"
  else
  end
  
  if ((geo.zip.to_i >= 19701) && (geo.zip.to_i <= 34997)) ||  ((geo.zip.to_i >= 39813) && (geo.zip.to_i <= 39901)) || ((geo.zip.to_i >= 56901) && (geo.zip.to_i <= 56972)) then
    geo.region = "South"
    geo.regionPrecode = "3"
    geo.division = "South Atlantic"
    geo.divisionPrecode = "5"
  else
  end
  
  if ((geo.zip.to_i >= 35004) && (geo.zip.to_i <= 39776)) ||  ((geo.zip.to_i >= 40003) && (geo.zip.to_i <= 42788)) then
    geo.region = "South"
    geo.regionPrecode = "3"
    geo.division = "East South Central"
    geo.divisionPrecode = "6"
  else
  end

  if ((geo.zip.to_i >= 70001) && (geo.zip.to_i <= 79999)) ||  ((geo.zip.to_i >= 88510) && (geo.zip.to_i <= 88595)) then
    geo.region = "South"
    geo.regionPrecode = "3"
    geo.division = "West South Central"
    geo.divisionPrecode = "7"
  else
  end

  if ((geo.zip.to_i >= 43001) && (geo.zip.to_i <= 49971)) ||  ((geo.zip.to_i >= 53001) && (geo.zip.to_i <= 54990)) || ((geo.zip.to_i >= 60001) && (geo.zip.to_i <= 62999)) then
    geo.region = "Midwest"
    geo.regionPrecode = "2"
    geo.division = "East North Central"
    geo.divisionPrecode = "3"
  else
  end
  
  if ((geo.zip.to_i >= 50001) && (geo.zip.to_i <= 52809)) ||  ((geo.zip.to_i >= 55001) && (geo.zip.to_i <= 56763)) || ((geo.zip.to_i >= 57001) && (geo.zip.to_i <= 58856)) || ((geo.zip.to_i >= 63001) && (geo.zip.to_i <= 69367)) then
    geo.region = "Midwest"
    geo.regionPrecode = "2"
    geo.division = "West North Central"
    geo.divisionPrecode = "4"
  else
  end
  
  if ((geo.zip.to_i >= 59001) && (geo.zip.to_i <= 59937)) ||  ((geo.zip.to_i >= 80001) && (geo.zip.to_i <= 88439)) || ((geo.zip.to_i >= 88901) && (geo.zip.to_i <= 89883)) then
    geo.region = "West"
    geo.regionPrecode = "4"
    geo.division = "Mountain"
    geo.divisionPrecode = "8"
  else
  end
  
  if ((geo.zip.to_i >= 90001) && (geo.zip.to_i <= 99950)) then
    geo.region = "West"
    geo.regionPrecode = "4"
    geo.division = "Pacific"
    geo.divisionPrecode = "9"
  else
  end
  
  geo.save

end