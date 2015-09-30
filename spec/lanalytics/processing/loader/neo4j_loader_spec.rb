require 'rails_helper'

describe Lanalytics::Processing::Loader::Neo4jLoader do
  if Lanalytics::Processing::DatasourceManager.datasource_exists?('exp_graph_schema_neo4j')

    before(:each) do
      @neo4j_datasource = Lanalytics::Processing::DatasourceManager.datasource('exp_graph_schema_neo4j')
      @neo4j_loader = Lanalytics::Processing::Loader::Neo4jLoader.new(@neo4j_datasource)
      @original_hash = double('original_hash')
      # expect(@original_hash).to_not receive()
    end

    before(:each) do
      Neo4jTestHelper.clean_database
    end

    def dummy_pipeline_ctx
      return Lanalytics::Processing::PipelineContext.new(
        Lanalytics::Processing::Pipeline.new(
          'xikolo.lanalytics.pipeline',
          :pipeline_spec,
          Lanalytics::Processing::Action::CREATE,
          [],
          [],
          [@neo4j_loader]
        ),
        {} # Empty options hash
      )
    end

    describe '(dealing with LoadORM:Entity)' do
      it 'should create entity' do
        punit = FactoryGirl.build(:dummy_punit)
        merge_command = FactoryGirl.build(:load_command_with_entity)
        pipeline_ctx = dummy_pipeline_ctx

        @neo4j_loader.load(punit, [merge_command], pipeline_ctx)

        result = @neo4j_datasource.exec do |session|
          session.query.match(r: {dummy_type: {dummy_uuid: '1234567890'}}).pluck(:r)
        end

        expect(result.length).to eq(1)
        expected_node = result.first
        expect(expected_node.labels).to include(:dummy_type)
        expect(expected_node.props).to include(dummy_uuid: '1234567890')
        expect(expected_node.props).to include(dummy_string_property: 'dummy_string_value')
        expect(expected_node.props).to include(dummy_int_property: 1234)
        expect(expected_node.props).to include(dummy_float_property: 1234.0)
        expect(expected_node.props).to include(dummy_timestamp_property: '2015-03-10 09:00:00 +0100')
      end



      it 'should destroy a resource' do
        # Create the node that should be deleted in this test
        @neo4j_datasource.exec do |session|
          session.query.create(r: {dummy_type: {dummy_uuid: '1234567890'}}).exec
        end

        punit = FactoryGirl.build(:dummy_punit)
        destroy_command = Lanalytics::Processing::LoadORM::DestroyCommand.new(
          Lanalytics::Processing::LoadORM::Entity.create(:dummy_type) do
            with_primary_attribute :dummy_uuid, :uuid, '1234567890'
          end
        )
        pipeline_ctx = dummy_pipeline_ctx

        @neo4j_loader.load(punit, [destroy_command], pipeline_ctx)

        result = @neo4j_datasource.exec do |session|
          session.query.match(r: {dummy_type: {dummy_uuid: '1234567890'}}).pluck(:r)
        end
        expect(result.length).to eq(0)
      end

    end

    # describe '(dealing with ContinuousRelationship)' do
    #   it 'should create a new relationship' do
    #     # resource = FactoryGirl.build(:stmt_resource)
    #     # @neo4j_processor.process(@original_hash, [resource], { processing_action: Lanalytics::Processing::Action::CREATE })

    #     # result = Neo4j::Session.query.match(r: {resource.type.to_sym.upcase => {resource_uuid: resource.uuid }}).pluck(:r)
    #     # expect(result.length).to eq(1)
    #     # expected_node = result.first
    #     # expect(expected_node.labels).to include(resource.type.to_sym.upcase)
    #     # expect(expected_node.props).to include(resource_uuid: resource.uuid)
    #     # expect(expected_node.props.keys).to include(:propertyA, :propertyB)
    #   end
    # end

    # describe '(dealing with Experience Statement)' do

    # end

  end
end
