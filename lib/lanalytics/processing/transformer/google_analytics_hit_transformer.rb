module Lanalytics
  module Processing
    module Transformer
      class GoogleAnalyticsHitTransformer < TransformStep
        include Lanalytics::Helper::HashHelper

        PROTOCOL_VERSION = 1
        APP_RUNTIMES = %w(Android iOS)
        DUMMY_UUID = '00000000-0000-0000-0000-000000000000'
        VERB_CATEGORIES = {
            pageviews: [:visited_question, :visited_item, :visited_pinboard, :visited_progress, :visited_learning_rooms,
                        :visited_announcements, :visited_recap, :visited_profile, :visited_documents, :visited_activity,
                        :visited_dashboard, :visited_preferences],
            video: [:video_play, :video_pause, :video_change_size, :video_change_speed, :video_change_quality,
                    :video_portrait, :video_landscape, :video_fullscreen, :video_seek, :video_close, :video_end],
            lti: [:submitted_lti],
            navigation: [:clicked_item_nav_prev, :navigated_prev_item, :clicked_item_nav_next, :navigated_next_item],
            download: [:downloaded_hd_video, :downloaded_sd_video, :downloaded_audio, :downloaded_slides, :downloaded_section],
            second_screen: [:second_screen_slides_start, :visited_second_screen_slides, :second_screen_slides_stop,
                            :second_screen_pinboard_start, :visited_second_screen_pinboard, :second_screen_pinboard_stop,
                            :second_screen_quiz_start, :second_screen_quiz_stop],
            pinboard: [:toggled_pinboard_question_form, :asked_question, :clicked_edit_question, :clicked_edit_answer,
                       :answered_question, :answer_accepted, :toggled_add_comment, :commented, :clicked_edit_comment,
                       :clicked_downvote, :clicked_upvote, :toggled_question_form, :toggled_subscription],
            social: [:share_button_click]
        }

        def initialize(datasource, geo_id_lookup)
          @datasource = datasource
          @geo_id_lookup = geo_id_lookup
        end

        def transform(_original_event, processing_units, load_commands, pipeline_ctx)
          processing_action = pipeline_ctx.processing_action.to_s.downcase

          processing_units.each do |processing_unit|
            processing_unit_type = processing_unit.type.to_s.downcase
            transform_method = "transform_#{processing_unit_type}_punit_to_#{processing_action}"
            if respond_to? transform_method.to_sym
              method(transform_method).call(processing_unit, load_commands)
            else
              Rails.logger.error "#{transform_method} does not exist"
            end
          end
        end

        def transform_attrs_to_create(load_commands, attrs)
          tracking_id = @datasource.tracking_id
          geo_id = @geo_id_lookup.get(attrs[:user_location_country_code], attrs[:user_location_city])
          entity = Lanalytics::Processing::LoadORM::Entity.create(:google_analytics_hit) do
            # General properties
            with_attribute :v,       :int,     PROTOCOL_VERSION
            with_attribute :tid,     :string,  tracking_id
            with_attribute :ds,      :string,  attrs[:data_source]
            with_attribute :qt,      :int,     (attrs[:timestamp]&.to_time || Time.now).to_i
            with_attribute :t,       :string,  attrs[:hit_type]

            # User properties
            with_attribute :uid,     :string,  (Digest::SHA256.hexdigest attrs[:user_id])
            with_attribute :cid,     :string,  (Digest::SHA256.hexdigest attrs[:client_id]) unless attrs[:client_id].nil?
            with_attribute :ua,      :string,  '' # Prevents GA from extracting user agent from HTTP request headers
            with_attribute :uip,     :string,  '' # Prevents GA from extracting IP from HTTP request
            unless geo_id.nil?
              with_attribute :geoid, :string,  geo_id
            end
            unless attrs[:screen_width].nil? or attrs[:screen_height].nil?
              with_attribute :sr,    :string,  "#{attrs[:screen_width]}x#{attrs[:screen_height]}"
            end

            # App tracking
            if attrs[:data_source] == :app
              with_attribute :an,    :string,  attrs[:app_name]
              with_attribute :av,    :string,  attrs[:app_version]
            end

            # Content information
            if attrs[:hit_type] == :pageview
              with_attribute :dh,    :string,  Xikolo.config.domain
              with_attribute :dp,    :string,  attrs[:document_path]
            end

            # Event tracking
            if attrs[:hit_type] == :event
              with_attribute :ec,    :string,  attrs[:event_category]
              with_attribute :ea,    :string,  attrs[:event_action]
              with_attribute :el,    :string,  attrs[:event_label]
              with_attribute :ev,    :int,     attrs[:event_value]
            end

            # Content groups
            (1..5).each do |n|
              cg_attr = "content_group_#{n}".to_sym
              unless attrs[cg_attr].nil?
                with_attribute :"cg#{n}", :string,  attrs[cg_attr]
              end
            end

            # Custom dimensions and metrics
            (1..20).each do |n|
              cd_attr = "cd#{n}".to_sym
              unless attrs[cd_attr].nil?
                with_attribute cd_attr, :string,  attrs[cd_attr]
              end

              cm_attr = "cm#{n}".to_sym
              unless attrs[cm_attr].nil?
                with_attribute cm_attr, :float,   attrs[cm_attr]
              end
            end
          end

          load_commands << Lanalytics::Processing::LoadORM::CreateCommand.with(entity)
        end

        # Transform events coming from Javascript through the web service.
        def transform_exp_event_punit_to_create(processing_unit, load_commands)
          exp_stmt = Lanalytics::Model::ExpApiStatement.new_from_json(processing_unit.data)
          verb = exp_stmt.verb.type.downcase
          cat = VERB_CATEGORIES.find{ |key, verbs| verbs.include? verb }&.first

          if cat.nil?
            Rails.logger.error "Verb #{verb} has not been mapped to a category"
          else
            transform_method = "transform_#{cat}_exp_stmt_to_create"
            if respond_to? transform_method.to_sym
              method(transform_method).call(exp_stmt, load_commands)
            else
              transform_exp_stmt_to_create exp_stmt, load_commands,
                                           hit_type: :event,
                                           event_category: cat,
                                           event_action: verb.to_sym
            end
          end
        end

        def transform_exp_stmt_to_create(exp_stmt, load_commands, attrs)
          in_context = hash_keys_to_underscore(exp_stmt.in_context)
          attrs = attrs.merge client_id: in_context[:client_id],
                              user_id: exp_stmt.user.uuid,
                              timestamp: exp_stmt.timestamp,
                              data_source: (APP_RUNTIMES.include? in_context[:runtime]) ? :app : :web,
                              app_name: in_context[:runtime],
                              app_version: in_context[:build_version],
                              screen_width: in_context[:screen_width]&.to_i,
                              screen_height: in_context[:screen_height]&.to_i,
                              user_location_country_code: in_context[:user_location_country_code],
                              user_location_city: in_context[:user_location_city],
                              custom_dimension(:platform) => in_context[:platform],
                              custom_dimension(:platform_version) => in_context[:platform_version],
                              custom_dimension(:runtime) => in_context[:runtime],
                              custom_dimension(:runtime_version) => in_context[:runtime_version],
                              custom_dimension(:device) => in_context[:device]
          if attrs[custom_dimension(:course_id)].nil?
            attrs[custom_dimension(:course_id)] = in_context[:course_id]
          end
          if exp_stmt.resource.type.downcase == :item
            attrs[custom_dimension(:item_id)] = sanitize_uuid exp_stmt.resource.uuid
            attrs[custom_dimension(:section_id)] = in_context[:section_id]
          end
          if exp_stmt.resource.type.downcase == :question
            attrs[custom_dimension(:question_id)] = sanitize_uuid exp_stmt.resource.uuid
          end

          transform_attrs_to_create(load_commands, attrs)
        end

        def transform_video_exp_stmt_to_create(exp_stmt, load_commands)
          verb = exp_stmt.verb.type.downcase
          in_context = hash_keys_to_underscore(exp_stmt.in_context)
          attrs = {
              hit_type: :event,
              event_category: :video,
              event_action: verb.to_sym,
              custom_metric(:video_time) => in_context[:current_time]&.to_f
          }
          case verb
            when :video_seek
              attrs[custom_metric(:video_time)] = in_context[:old_current_time]&.to_f
              if in_context[:new_current_time].present? && in_context[:old_current_time].present?
                attrs[:event_label] = in_context[:new_current_time].to_f > in_context[:old_current_time].to_f ? :forward : :backward
              end
            when :video_change_quality
              attrs[:event_label] = in_context[:new_quality]
            when :video_change_speed
              attrs[:event_label] = in_context[:new_speed]
            when :video_fullscreen
              attrs[:event_label] = in_context[:new_current_fullscreen] == 'true' ? :enabled : :disabled
          end

          transform_exp_stmt_to_create exp_stmt, load_commands, attrs
        end

        def transform_lti_exp_stmt_to_create(exp_stmt, load_commands)
          verb = exp_stmt.verb.type.downcase
          in_context = hash_keys_to_underscore(exp_stmt.in_context)
          transform_exp_stmt_to_create exp_stmt, load_commands,
                                       hit_type: :event,
                                       event_category: :lti,
                                       event_action: verb.to_sym,
                                       custom_metric(:points_percentage) => percentage(in_context[:points]&.to_f, in_context[:max_points]&.to_f)
        end

        def transform_pageviews_exp_stmt_to_create(exp_stmt, load_commands)
          verb = exp_stmt.verb.type.downcase
          in_context = hash_keys_to_underscore(exp_stmt.in_context)
          course_id = exp_stmt.resource.type.downcase == :course ? (sanitize_uuid exp_stmt.resource.uuid) : (in_context[:course_id])
          attrs = {
              hit_type: :pageview,
              document_path: get_document_path(verb, course_id, sanitize_uuid(exp_stmt.resource.uuid)),
              custom_dimension(:course_id) => course_id
          }

          transform_exp_stmt_to_create exp_stmt, load_commands, attrs

        end

        def transform_question_punit_to_create(processing_unit, load_commands)
          transform_attrs_to_create load_commands,
                                    hit_type: :event,
                                    data_source: :service,
                                    event_category: :pinboard,
                                    event_action: :asked_question,
                                    user_id: processing_unit[:user_id],
                                    timestamp: processing_unit[:created_at],
                                    custom_dimension(:course_id) => processing_unit[:course_id],
                                    custom_dimension(:item_id) => processing_unit[:video_id],
                                    custom_dimension(:question_id) => processing_unit[:id],
                                    custom_metric(:video_time) => processing_unit[:video_timestamp]
        end


        def transform_answer_punit_to_create(processing_unit, load_commands)
          transform_attrs_to_create load_commands,
                                    hit_type: :event,
                                    data_source: :service,
                                    event_category: :pinboard,
                                    event_action: :answered_question,
                                    user_id: processing_unit[:user_id],
                                    timestamp: processing_unit[:created_at],
                                    custom_dimension(:course_id) => processing_unit[:course_id],
                                    custom_dimension(:question_id) => processing_unit[:question_id]
        end

        def transform_comment_punit_to_create(processing_unit, load_commands)
          transform_attrs_to_create load_commands,
                                    hit_type: :event,
                                    data_source: :service,
                                    event_category: :pinboard,
                                    event_action: :commented,
                                    user_id: processing_unit[:user_id],
                                    timestamp: processing_unit[:created_at],
                                    custom_dimension(:course_id) => processing_unit[:course_id],
                                    custom_dimension(:question_id) => processing_unit[:commentable_id]
        end

        def transform_answer_accepted_punit_to_create(processing_unit, load_commands)
          transform_attrs_to_create load_commands,
                                    hit_type: :event,
                                    data_source: :service,
                                    event_category: :pinboard,
                                    event_action: :answer_accepted,
                                    user_id: processing_unit[:user_id],
                                    timestamp: processing_unit[:created_at],
                                    custom_dimension(:course_id) => processing_unit[:course_id],
                                    custom_dimension(:question_id) => processing_unit[:question_id]
        end

        def transform_enrollment_punit_to_create(processing_unit, load_commands)
          save_enrollment(processing_unit, load_commands)
        end

        def transform_enrollment_punit_to_update(processing_unit, load_commands)
          save_enrollment(processing_unit, load_commands)
        end

        def save_enrollment(processing_unit, load_commands)
          action = processing_unit[:deleted] ? :un_enrolled : :enrolled
          transform_attrs_to_create load_commands,
                                    hit_type: :event,
                                    data_source: :service,
                                    event_category: :course,
                                    event_action: action,
                                    user_id: processing_unit[:user_id],
                                    timestamp: processing_unit[:created_at],
                                    custom_dimension(:course_id) => processing_unit[:course_id]
        end

        def transform_user_punit_to_create(processing_unit, load_commands)
          transform_attrs_to_create load_commands,
                                    hit_type: :event,
                                    data_source: :service,
                                    event_category: :user,
                                    event_action: :confirmed_user,
                                    user_id: processing_unit[:id],
                                    timestamp: processing_unit[:updated_at]
        end

        def transform_submission_punit_to_create(processing_unit, load_commands)
          submission_time = processing_unit[:quiz_submission_time]&.to_time || Time.now
          transform_attrs_to_create load_commands,
                                    hit_type: :event,
                                    data_source: :service,
                                    event_category: :quiz,
                                    event_action: :submitted_quiz,
                                    user_id: processing_unit[:user_id],
                                    timestamp: submission_time,
                                    custom_dimension(:course_id) => processing_unit[:course_id],
                                    custom_dimension(:item_id) => processing_unit[:item_id],
                                    custom_dimension(:quiz_type) => processing_unit[:quiz_type],
                                    custom_metric(:points_percentage) => percentage(processing_unit[:points], processing_unit[:max_points]),
                                    custom_metric(:quiz_attempt) => processing_unit[:attempt],
                                    custom_metric(:quiz_needed_time) => submission_time - (processing_unit[:quiz_access_time]&.to_time || 0)
        end

        def custom_dimension(name)
          index = @datasource.custom_dimension_index name
          "cd#{index}".to_sym
        end

        def custom_metric(name)
          index = @datasource.custom_metric_index name
          "cm#{index}".to_sym
        end

        def sanitize_uuid(id)
          # Resources might have a dummy uuid, if not applicable in the context of the event
          id unless id == DUMMY_UUID
        end

        def percentage(value, total)
          value / total.to_f * 100 if (value.is_a? Numeric) && (total.is_a? Numeric) && total != 0
        end

        def get_document_path(verb, course_id = nil, resource_id = nil)
          case verb
            when :visited_question
              "/courses/#{course_id}/question/#{resource_id}"
            when :visited_item
              "/courses/#{course_id}/item/#{resource_id}"
            when :visited_pinboard
              "/courses/#{course_id}/pinboard"
            when :visited_learning_rooms
              "/courses/#{course_id}/learning_rooms"
            when :visited_announcements
              course_id.nil? ? "/news" : "/courses/#{course_id}/announcements"
            when :visited_recap
              "/courses/#{course_id}/recap"
            when :visited_dashboard
              "/dashboard"
            when :visited_profile
              "/dashboard/profile"
            when :visited_documents
              "/dashboard/documents"
            when :visited_activity
              "/dashboard/activity"
            when :visited_preferences
              "/preferences"
          end
        end
      end
    end
  end
end
