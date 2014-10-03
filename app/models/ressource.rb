class Ressource
  include Neo4j::ActiveNode

  property :type
  property :ressource_uuid

  index :ressource_uuid
end
