Xikolo::Lanalytics::Application.config.data_dir = if Rails.env.production?
                                             Pathname.new '/var/lib/xikolo/data'
                                           elsif Rails.env.integration?
                                             Rails.root.parent.join('data_integration')
                                           else
                                             Rails.root.parent.join('data')
                                           end
