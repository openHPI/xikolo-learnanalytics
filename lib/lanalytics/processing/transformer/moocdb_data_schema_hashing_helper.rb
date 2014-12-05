module Lanalytics
  module Processing
    module Transformer
      class MoocdbDataSchemaHashingHelper
        class << self
          # Hashing functions from the gem 'Murmurhash3'
          # More details on https://github.com/funny-falcon/murmurhash3-ruby
          # include MurmurHash32::V32
          # include MurmurHash32::V128
          def murmur_hash(global_user_id, seed)
            # return MurmurHash3::V128.fmix(MurmurHash3::V32.str_hash(global_user_id, seed))
            # Returns an unsigned long (32bit)
            return MurmurHash3::V32.str_hash(global_user_id, seed)
          end

          def hash_to_course_user_id(global_user_id)
            return murmur_hash(global_user_id, 1)
          end

          def hash_to_observing_user_id(global_user_id)
            return murmur_hash(global_user_id, 2)
          end

          def hash_to_submitting_user_id(global_user_id)
            return murmur_hash(global_user_id, 3)
          end

          def hash_to_collaborating_user_id(global_user_id)
            return murmur_hash(global_user_id, 4)
          end

          def hash_to_feedback_user_id(global_user_id)
            return murmur_hash(global_user_id, 5)
          end
          
          def hash_to_resource_type_id(type_content, type_medium)
            return murmur_hash(type_content + type_medium, 6) / 2
          end

          def hash_to_url_id(course_id, item_id)
            return murmur_hash("#{course_id}::#{item_id}", 7) / 2
          end

          # def hash_to_resource_url_id(resource_id, course_id, item_id)
          #   return murmur_hash("#{course_id}::#{item_id}", 7) / 2
          # end

        end
      end
    end
  end
end