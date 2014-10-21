json.array!(@research_cases) do |research_case|
  json.extract! research_case, :id, :title
  json.url research_case_url(research_case, format: :json)
end
