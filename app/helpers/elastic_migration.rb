# frozen_string_literal: true

##
# To support a migration of our production system's ElasticSearch clusters, the
# code needs to support both the old and the new version of ElasticSearch.
#
# To enable this, this module offers two helper methods that encapsulate the
# logic that is different between the two versions. On production, the new
# behavior can be transparently enabled by adding a new key to +Xikolo.config+.
#
# This module and all its call sites can be removed again (and replaced by the
# v7 versions) once the migration of all production systems has been completed.
#
module ElasticMigration
  class << self
    ##
    # Safely unpack the result of an ElasticSearch query.
    #
    def result(structure)
      if migrated?
        structure && structure['value']
      else
        structure
      end
    end

    ##
    # Determine the correct entity key for use with write operations.
    #
    def entity_key(entity)
      if migrated?
        '_doc'
      else
        entity.entity_key
      end
    end

    private

    def migrated?
      Xikolo.config.elasticsearch_migrated == true
    end
  end
end
