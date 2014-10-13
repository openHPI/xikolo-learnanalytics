class LanalyticsConsumer < Msgr::Consumer

  def update

    puts "#{payload.inspect}"
    if payload[:verb] == "CREATE" or payload[:verb] == "UPDATE"
      ressource_type = payload[:ressource_type]
      ressource = payload[:ressource].with_indifferent_access
      ressource_uuid = ressource[:ressource_uuid]
      ressource_properties = ressource.except(:relationships)
      # ::TODO This is not beautiful, but necessary for the moment; Neo4jrb is not able to deal with nil values
      ressource_properties.delete_if {|key, value| value.nil? }
      Neo4j::Session.query
        .merge(r: {ressource_type.to_sym => {ressource_uuid: ressource_uuid }})
        .on_create_set(r: ressource_properties)
        .on_match_set(r: ressource_properties)
        .pluck(:r)

      if ressource.has_key?(:relationships) and not ressource[:relationships].nil? and not ressource[:relationships].empty?
        for relationship in ressource[:relationships]
          relationship_properties = relationship.except(*%w(with_rel_type to_ressource_type to_ressource_uuid))
          # ::TODO:: Issue this as a github issue
          Neo4j::Session.query
            .merge(r1: {ressource_type.to_sym => {ressource_uuid: ressource[:ressource_uuid] }}).break
            .merge(r2: {relationship[:to_ressource_type].to_sym => {ressource_uuid: relationship[:to_ressource_uuid] }}).break
            .merge("(r1)-[:#{relationship[:with_rel_type]} #{Neo4j::Core::Query.new.merge(relationship_properties).to_cypher[8..-2]}]->(r2)")
            .pluck(:r1)
        end
      end

    end

  end


  def handle_user_event
    puts "#{payload.inspect}"

    exp_stmt = Lanalytics::Model::ExpApiStatement.new_from_json(payload)

    Neo4j::Session.query
    .merge(r1: {exp_stmt.user.type => { ressource_uuid: exp_stmt.user.uuid }}).break
    .merge(r2: {exp_stmt.resource.type => { ressource_uuid: exp_stmt.resource.uuid }}).break
    .create("(r1)-[:#{exp_stmt.verb.type} #{Neo4j::Core::Query.new.merge(exp_stmt.with_result).to_cypher[8..-2]}]->(r2)")
    .exec
  end
end
