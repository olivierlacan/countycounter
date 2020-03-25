require "net/http"
require "json"
require "csv"
require "date"

STATES = [
  illinois: {
    url: "http://www.dph.illinois.gov/sites/default/files/COVID19/COVID19CountyResults20200323.json",
    root_node: ["characteristics_by_county", "values"],
    schema: {
      county: "County",
      positives: "confirmed_cases",
      deaths: "deaths"
    }
  },
  louisiana: {
    url: "https://services5.arcgis.com/O5K6bb5dZVZcTo5M/arcgis/rest/services/Cases_by_Parish_2/FeatureServer/0/query?f=json&where=PFIPS%20%3C%3E%2099999&returnGeometry=false&spatialRel=esriSpatialRelIntersects&outFields=*&orderByFields=Deaths%20desc%2CCases%20desc%2CParish%20asc&resultOffset=0&resultRecordCount=65&cacheHint=true",
    root_node: ["features"],
    child_node: ["attributes"],
    schema: {
      county: "Parish",
      positives: "Cases",
      deaths: "Deaths"
    }
  },
  florida: {
    url: "https://services1.arcgis.com/CY1LXxl9zlJeBuRZ/ArcGIS/rest/services/Florida_COVID19_Case_Line_Data/FeatureServer/0/query?where=1%3D1&objectIds=&time=&resultType=none&outFields=*&returnIdsOnly=false&returnUniqueIdsOnly=false&returnCountOnly=false&returnDistinctValues=false&cacheHint=false&orderByFields=&groupByFieldsForStatistics=&outStatistics=&having=&resultOffset=&resultRecordCount=&sqlFormat=none&f=pjson",
    root_node: ["features"],
    group_by: ["attributes", "County"],
    schema: {
      county: -> { _1.first },
      positives: -> { _1.last.count },
      deaths: -> { _1.last.select { |c| c["attributes"]["Died"] == "Yes" }.count }
    }
  },
  texas: {
    url: "https://services5.arcgis.com/ACaLB9ifngzawspq/ArcGIS/rest/services/COVID19County_MobileFriendly/FeatureServer/0/query?where=1%3D1&objectIds=&time=&geometry=&geometryType=esriGeometryEnvelope&inSR=&spatialRel=esriSpatialRelIntersects&resultType=none&distance=0.0&units=esriSRUnit_Meter&returnGeodetic=false&outFields=*&returnGeometry=false&returnCentroid=false&featureEncoding=esriDefault&multipatchOption=xyFootprint&maxAllowableOffset=&geometryPrecision=&outSR=&datumTransformation=&applyVCSProjection=false&returnIdsOnly=false&returnUniqueIdsOnly=false&returnCountOnly=false&returnExtentOnly=false&returnQueryGeometry=false&returnDistinctValues=false&cacheHint=false&orderByFields=&groupByFieldsForStatistics=&outStatistics=&having=&resultOffset=&resultRecordCount=&returnZ=false&returnM=false&returnExceededLimitFeatures=true&quantizationParameters=&sqlFormat=none&f=pjson&token=",
    schema: {
      county: "County",
      positives: "Count_",
      deaths: "Deaths"
    }
  }
]

STATES.each do |state|
  puts "Processing #{state.first.first} ..."
  body = Net::HTTP.get(URI(state.last[:url]))
  json = JSON.parse(body)

  binding.irb

  CSV.open("#{state.first.first.downcase}#{Date.today.iso8601}.csv", "wb") do |csv|
    csv << %w[County Positives Deaths Date State]

    enumerator = state[:root_node] ? json[state[:root_node]] : json

    enumerator.each do |row|
      county = state[:schema][:county].respond_to?(:call) ? state[:schema][:county].call : json[state[:schema][:county]]
      positives = state[:schema][:positives].respond_to?(:call) ? state[:schema][:positives].call : json[state[:schema][:positives]]
      deaths = state[:schema][:deaths].respond_to?(:call) ? state[:schema][:deaths].call : json[state[:schema][:deaths]]

      csv << [county, positives, deaths, Date.today.iso8601, state]
    end
  end
end

# il_uri = URI('http://www.dph.illinois.gov/sites/default/files/COVID19/COVID19CountyResults20200323.json')
# il_raw = Net::HTTP.get(il_uri)
# il_json = JSON.parse(il_raw)

# puts "Illinois"
# CSV.open("illinois.csv", "wb") do |csv|
#   csv << %w[County Positives Deaths  Date  State]

#   il_json["characteristics_by_county"]["values"].each do |row|
#     csv << [row["County"], row["confirmed_cases"], row["deaths"], "20200324", "IL"]
#     # County: "Illinois",
#     # confirmed_cases: 1285,
#     # total_tested: 9868,
#     # negative: 0,
#     # deaths: 12,
#     # lat: 0,
#     # lon: 0
#   end
# end

# la_uri = URI("https://services5.arcgis.com/O5K6bb5dZVZcTo5M/arcgis/rest/services/Cases_by_Parish_2/FeatureServer/0/query?f=json&where=PFIPS%20%3C%3E%2099999&returnGeometry=false&spatialRel=esriSpatialRelIntersects&outFields=*&orderByFields=Deaths%20desc%2CCases%20desc%2CParish%20asc&resultOffset=0&resultRecordCount=65&cacheHint=true")
# la_raw = Net::HTTP.get(la_uri)
# la_json = JSON.parse(la_raw)

# puts "Louisiana"
# CSV.open("louisiana.csv", "wb") do |csv|
#   csv << %w[County Positives Deaths  Date  State]

#   la_json["features"].each do |row|
#     attribute = row["attributes"]
#     csv << [attribute["Parish"], attribute["Cases"], attribute["Deaths"], "20200324", "LA"]
#       # OBJECTID: 35,
#       # PFIPS: "22069",
#       # Latitude: 31.72424,
#       # Longitude: -93.0963,
#       # LDHH: 7,
#       # Parish: "Natchitoches",
#       # Cases: 2,
#       # Deaths: 0,
#       # FID: 35
#   end
# end

# la_uri = URI("https://services5.arcgis.com/O5K6bb5dZVZcTo5M/arcgis/rest/services/Cases_by_Parish_2/FeatureServer/0/query?f=json&where=PFIPS%20%3C%3E%2099999&returnGeometry=false&spatialRel=esriSpatialRelIntersects&outFields=*&orderByFields=Deaths%20desc%2CCases%20desc%2CParish%20asc&resultOffset=0&resultRecordCount=65&cacheHint=true")
# la_raw = Net::HTTP.get(la_uri)
# la_json = JSON.parse(la_raw)

# puts "Louisiana"
# CSV.open("louisiana.csv", "wb") do |csv|
#   csv << %w[County Positives Deaths  Date  State]

# fl_uri = URI "https://services1.arcgis.com/CY1LXxl9zlJeBuRZ/ArcGIS/rest/services/Florida_COVID19_Case_Line_Data/FeatureServer/0/query?where=1%3D1&objectIds=&time=&resultType=none&outFields=*&returnIdsOnly=false&returnUniqueIdsOnly=false&returnCountOnly=false&returnDistinctValues=false&cacheHint=false&orderByFields=&groupByFieldsForStatistics=&outStatistics=&having=&resultOffset=&resultRecordCount=&sqlFormat=none&f=pjson"
# fl_raw = Net::HTTP.get(fl_uri)
# fl_json = JSON.parse(fl_raw)
# puts "Florida"
# CSV.open("florida.csv", "wb") do |csv|
#   csv << %w[County Positives Deaths Date State]

#   fl_json["features"].group_by { |row| row["attributes"]["County"] }.map do |county|
#     # County: "Dade",
#     # Age: "38",
#     # Gender: "Male",
#     # Jurisdiction: "FL resident",
#     # Travel_related: "No",
#     # Origin: "NA",
#     # EDvisit: "Yes",
#     # Hospitalized: "No",
#     # Died: "NA",
#     # Contact: "Unknown",
#     # Case_: 1584835200000,
#     # EventDate: 1584662400000,
#     # ObjectId: 6
#     csv << [
#       county.first,
#       county.last.count,
#       county.last.select { |c| c["attributes"]["Died"] == "Yes" }.count,
#       "20200324",
#       "FL"
#     ]
#   end
# end

# puts "Texas"
# tx_uri = URI "https://services5.arcgis.com/ACaLB9ifngzawspq/ArcGIS/rest/services/COVID19County_MobileFriendly/FeatureServer/0/query?where=1%3D1&objectIds=&time=&geometry=&geometryType=esriGeometryEnvelope&inSR=&spatialRel=esriSpatialRelIntersects&resultType=none&distance=0.0&units=esriSRUnit_Meter&returnGeodetic=false&outFields=*&returnGeometry=false&returnCentroid=false&featureEncoding=esriDefault&multipatchOption=xyFootprint&maxAllowableOffset=&geometryPrecision=&outSR=&datumTransformation=&applyVCSProjection=false&returnIdsOnly=false&returnUniqueIdsOnly=false&returnCountOnly=false&returnExtentOnly=false&returnQueryGeometry=false&returnDistinctValues=false&cacheHint=false&orderByFields=&groupByFieldsForStatistics=&outStatistics=&having=&resultOffset=&resultRecordCount=&returnZ=false&returnM=false&returnExceededLimitFeatures=true&quantizationParameters=&sqlFormat=none&f=pjson&token="
# tx_raw = Net::HTTP.get(tx_uri)
# tx_json = JSON.parse(tx_raw)
# CSV.open("texas.csv", "wb") do |csv|
#   csv << %w[County Positives Deaths Date State]

#   tx_json["features"].each do |row|
#     attributes = row["attributes"]
#     csv << [attributes["County"], attributes["Count_"], attributes["Deaths"], "20200324", "TX"]
#       # OBJECTID_1: 16,
#       # OBJECTID: 16,
#       # County: "Blanco",
#       # FIPS: "48031",
#       # COUNTYFP10: "031",
#       # Shape_Leng: 175706.904108,
#       # Count_: 1,
#       # LastUpdate: 1585063134446,
#       # Shape__Area: 1840476293.8877,
#       # Shape__Length: 175706.904107902,
#       # CreationDate: 1584391081676,
#       # Creator: "nfotheringham308",
#       # EditDate: 1585075853860,
#       # Editor: "nfotheringham308",
#       # Deaths: null
#   end
# end


# ar_uri = URI "https://services.arcgis.com/PwY9ZuZRDiI5nXUB/ArcGIS/rest/services/ADH_COVID19_Positive_Test_Results/FeatureServer/0/query?f=json&where=1%3D1&returnGeometry=false&spatialRel=esriSpatialRelIntersects&outFields=*"
# ar_raw = Net::HTTP.get(ar_uri)
# ar_json = JSON.parse(ar_raw)
# puts "Arkansas"
# CSV.open("arkansas.csv", "wb") do |csv|


