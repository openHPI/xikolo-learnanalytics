# frozen_string_literal: true

module Lanalytics
  module Processing
    class Pipeline
      attr_reader :name, :schema, :processing_action

      def initialize(name, schema, processing_action, extractors = [], transformers = [], loaders = [], &block)
        # Check mandatory fields
        if name.blank?
          raise ArgumentError.new "'#{name}' cannot be nil or empty"
        end

        if schema.blank?
          raise ArgumentError.new "'#{schema}' cannot be nil"
        end

        if processing_action.nil? || !Lanalytics::Processing::Action.valid(processing_action)
          raise ArgumentError.new "'#{processing_action}' is not accepted; only 'Action::{CREATE, UPDATE, DESTROY, UNDEFINED}' are accepted"
        end

        extractors ||= []
        extractors.each_with_index do |extract_step, i|
          unless extract_step.is_a?(Lanalytics::Processing::Extractor::ExtractStep)
            raise ArgumentError.new "Element #{i} in extractors is a '#{extract_step.class.name}', but needs to be a 'Lanalytics::Processing::Extractor::ExtractStep'"
          end
        end

        transformers ||= []
        transformers.each_with_index do |transform_step, i|
          unless transform_step.is_a?(Lanalytics::Processing::Transformer::TransformStep)
            raise ArgumentError.new "Element #{i} in transformers is a '#{transform_step.class.name}', but needs to be a 'Lanalytics::Processing::Transformer::TransformStep'"
          end
        end

        loaders ||= []
        loaders.each_with_index do |load_step, i|
          unless load_step.is_a?(Lanalytics::Processing::Loader::LoadStep)
            raise ArgumentError.new "Element #{i} in loaders is a '#{load_step.class.name}', but needs to be a 'Lanalytics::Processing::Loader::LoadStep'"
          end
        end

        @name              = name
        @schema            = schema.to_sym
        @processing_action = processing_action
        @extractors        = extractors
        @transformers      = transformers
        @loaders           = loaders

        instance_eval(&block) if block_given?

        # TODO:: Check for validity and type
      end

      # These methods are used inside the block when block is initialized ...
      def extractor(extractor)
        unless extractor && extractor.is_a?(Lanalytics::Processing::Extractor::ExtractStep)
          raise ArgumentError.new 'Needs to be of type \'ExtractStep\'.'
        end

        @extractors << extractor
      end

      def transformer(transformer)
        unless transformer && transformer.is_a?(Lanalytics::Processing::Transformer::TransformStep)
          raise ArgumentError.new 'Needs to be of type \'TransformerStep\'.'
        end

        @transformers << transformer
      end

      def loader(loader)
        unless loader && loader.is_a?(Lanalytics::Processing::Loader::LoadStep)
          raise ArgumentError.new 'Needs to be of type \'LoadStep\'.'
        end

        @loaders << loader
      end

      def loaders_available?
        @loaders.all?(&:available?)
      end

      def full_name
        "#{schema}::#{name}"
      end

      def process(original_event, processing_opts = {})
        processing_opts ||= {}

        unless original_event
          Rails.logger.info 'Data that should be imported is nil; there is nothing to process ...'
          return
        end

        original_event = original_event.with_indifferent_access

        pipeline_ctx = Lanalytics::Processing::PipelineContext.new(self, processing_opts)

        processing_units = []
        @extractors.each do |extractor|
          extractor.extract(original_event, processing_units, pipeline_ctx)
        end

        # Take care of 'processing_units' and 'load_commands'
        # because these arrays are mutable and are modified in the transformation steps
        load_commands = []
        @transformers.each do |transformer|
          transformer.transform(original_event, processing_units, load_commands, pipeline_ctx)
        end

        @loaders.each do |loader|
          loader.load(original_event, load_commands, pipeline_ctx)
        end
      end
    end
  end
end
