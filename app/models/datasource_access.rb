class DatasourceAccess < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :research_case, optional: true
  belongs_to :datasource, foreign_key: 'datasource_key', optional: true
  serialize :channel, Channel
end
