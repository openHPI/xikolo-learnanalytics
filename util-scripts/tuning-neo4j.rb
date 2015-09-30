require 'neo4j-core'
require './lib/lanalytics/model/stmt_resource'
require 'active_support/core_ext/hash/indifferent_access'

require 'ruby-prof'

# Profile the code
# result = RubyProf.profile do

  session = Neo4j::Session.open(:server_db, 'http://localhost:8474')
  puts session.inspect

  # Neo4j::Transaction.run do

    # session.query('CREATE INDEX ON :USER(resource_uuid)')


    time = Time.now
    total_query_execution_time = 0
    10000.times do |i|

      resource =
        Lanalytics::Model::StmtResource.new(
          :USER,
          "00000001-3100-4444-9999-%012d" % i,
          admin: false,
          language: 'en',
          archived: false,
          created_at: '2014-10-20T19:56:34Z',
          confirmed: true,
          affiliated: false,
          updated_at: '2014-10-20T19:56:34Z'
        )

      resource_type = resource.type
      resource_uuid = resource.uuid
      resource_properties = resource.properties.merge(resource_uuid: resource_uuid)


      query_execution_time = Time.now
      session.query
                  .merge(r: {resource_type => {resource_uuid: resource_uuid }})
                  .on_create_set(r: resource_properties)
                  .on_match_set(r: resource_properties)
                  .exec
      total_query_execution_time += (Time.now - query_execution_time)
      print "Inserting a user average time (#{i+1}): #{total_query_execution_time/(i+1)}\r"
      # print "Inserting a user average time: #{total_query_execution_time / (i+1)}\r"
    end

    puts
    puts "Users #{Time.now - time}"
    time = Time.now

    total_query_execution_time = 0
    10.times do |i|

      resource =
        Lanalytics::Model::StmtResource.new(
          :COURSE,
          "00000001-3300-4444-9999-%012d" % i,
          title: "Hidden Course #{i}",
          start_date: "2016-06-23T00:00:00Z",
          display_start_date: "2016-06-23T00:00:00Z",
          end_date: "2016-08-24T00:00:00Z",
          abstract: "This course is hidden.")

      resource_type = resource.type
      resource_uuid = resource.uuid
      resource_properties = resource.properties.merge(resource_uuid: resource_uuid)

      query_execution_time = Time.now
      session.query
                  .merge(r: {resource_type => {resource_uuid: resource_uuid }})
                  .on_create_set(r: resource_properties)
                  .on_match_set(r: resource_properties)
                  .exec
      total_query_execution_time += (Time.now - query_execution_time)
      print "Inserting a course average time (#{i+1}): #{total_query_execution_time / (i+1)}\r"
    end
    puts
    puts "Course #{Time.now - time}"
    time = Time.now

    total_query_execution_time = 0
    10000.times do |i|

      5.times do |j|

        query_execution_time = Time.now
        session.query
          .merge(r1: {:USER => {resource_uuid: "00000001-3100-4444-9999-%012d" % i }}).break
          .merge(r2: {:COURSE => {resource_uuid: "00000001-3300-4444-9999-%012d" % j }}).break
          .merge("(r1)-[:ENROLLED]->(r2)")
          .exec
        total_query_execution_time += (Time.now - query_execution_time)
        print "Inserting a enrollment average time (#{5*i + (j+1)}): #{total_query_execution_time / (5*i + (j+1))}\r"
      end
    end
    puts
    puts "Enrollement #{Time.now - time}"
  # end
# end

# printer = RubyProf::GraphPrinter.new(result)
# printer.print(STDOUT, {})
