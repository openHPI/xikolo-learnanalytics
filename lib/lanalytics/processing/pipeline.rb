module Lanalytics
  module Processing
    class Pipeline
      attr_reader :name, :schema, :processing_action

      def initialize(name, schema, processing_action, extractors = [], transformers = [], loaders = [], &block)
        # Check mandatory fields
        raise ArgumentError.new "'#{name}' cannot be nil or empty" if name.nil? or name.empty? 
        raise ArgumentError.new "'#{schema}' cannot be nil" if schema.nil? or schema.empty? 
        raise ArgumentError.new ("'#{processing_action}' is not accepted; only 'ProcessingAction::{CREATE, UPDATE, DESTROY, UNDEFINED}' are accepted") if processing_action.nil? or not Lanalytics::Processing::ProcessingAction.valid(processing_action)

        extractors ||= []
        extractors.each_with_index do | extract_step, i |
          raise ArgumentError.new("Element #{i} in extractors is a '#{extract_step.class.name}', but needs to be an 'Lanalytics::Processing::Extractor::ExtractStep'") unless extract_step.is_a?(Lanalytics::Processing::Extractor::ExtractStep)
        end 

        transformers ||= []
        transformers.each_with_index do | transform_step, i |
          raise ArgumentError.new("Element #{i} in transformers is a '#{transform_step.class.name}', but needs to be an 'Lanalytics::Processing::Transformer::TransformStep'") unless transform_step.is_a?(Lanalytics::Processing::Transformer::TransformStep)
        end

        loaders ||= []
        loaders.each_with_index do | load_step, i |
          raise ArgumentError.new("Element #{i} in loaders is a '#{load_step.class.name}', but needs to be an 'Lanalytics::Processing::Loader::LoadStep'") unless load_step.is_a?(Lanalytics::Processing::Loader::LoadStep)
        end

        @name, @schema, @processing_action, @extractors, @transformers, @loaders = name, schema.to_sym, processing_action, extractors, transformers, loaders
        
        instance_eval(&block) if block_given?

        # TODO:: Check for validity and type
      end
      
      # These methods are used inside the block when block is initialized ...
      def extractor(extractor)
        raise ArgumentError.new('Needs to be of type \'ExtractStep\'!!') unless extractor and extractor.is_a?(Lanalytics::Processing::Extractor::ExtractStep)
        @extractors << extractor
      end

      def transformer(transformer)
        raise ArgumentError.new('Needs to be of type \'TransformerStep\'!!') unless transformer and transformer.is_a?(Lanalytics::Processing::Transformer::TransformStep)
        @transformers << transformer
      end

      def loader(loader)
        raise ArgumentError.new('Needs to be of type \'LoadStep\'!!') unless loader and loader.is_a?(Lanalytics::Processing::Loader::LoadStep)
        @loaders << loader
      end

      def full_name
        return "#{schema}::#{name}"
      end

      def process(original_event, processing_opts = {})

        processing_opts ||= {}

        unless original_event
          Rails.logger.info 'Data that should be imported is nil; there is nothing to process ...'
          return
        end

        original_event = original_event.with_indifferent_access

        pipeline_ctx = PipelineContext.new(self, processing_opts)

        processing_units = []
        @extractors.each do | extractor |
          extractor.extract(original_event, processing_units, pipeline_ctx)
        end

        # Take care of 'processing_units' and 'load_commands' because these arrays are mutable and are modified in the transformation steps
        load_commands = []
        @transformers.each do | transformer |
          
          Rails.logger.debug(%Q{
            Transformer #{transformer.class.name} received the following processing units:
            #{processing_units.inspect}
          })

          transformer.transform(original_event, processing_units, load_commands, pipeline_ctx)

          Rails.logger.debug(%Q{
            Transformer #{transformer.class.name} transformed to the following load commands:
            #{load_commands.inspect} 
          })
        end

        @loaders.each do | loader |
          loader.load(original_event, load_commands, pipeline_ctx)
        end
      end

    end

    class PipelineContext
      attr_reader :pipeline
      def initialize(pipeline, opts = {})
        @pipeline = pipeline

        opts ||= {}
        @opts = opts
      end

      def name
        return @pipeline.name
      end

      def processing_action
        return @pipeline.processing_action
      end
    end
  end
end
