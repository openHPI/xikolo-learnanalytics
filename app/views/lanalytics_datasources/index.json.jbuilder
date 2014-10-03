json.array!(@lanalytics_datasources) do |lanalytics_datasource|
  json.extract! lanalytics_datasource, :id, :name, :root_url
  json.url lanalytics_datasource_url(lanalytics_datasource, format: :json)
end
