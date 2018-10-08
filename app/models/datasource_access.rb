class DatasourceAccess < ApplicationRecord
  belongs_to :user
  belongs_to :research_case
  belongs_to :datasource, foreign_key: 'datasource_key' 
  serialize :channel, Channel
end
