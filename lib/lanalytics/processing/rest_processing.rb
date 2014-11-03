module Lanalytics
  module Processing
    class RestProcessing

      def initialize(url, processing_steps)
        @url = url
        @processing_chain = Lanalytics::Processing::ProcessingChain.new(processing_steps)
      end

      def process

        progress_bar = create_progress_bar

        current_url_page = @url

        first_round = true

        begin

          begin
            rest_response = RestClient.get(current_url_page)
            rest_response_data = MultiJson.load(rest_response, symbolize_keys: true)
          rescue Exception => any_error
            puts "Lanalytics Datasource on url (#{@url}) could not be processed and failed with the following error:\033[K"
            puts "#{any_error.message[0..100]}..."
            break
          end

          unless rest_response.headers[:link]
            progress_bar.total = rest_response_data.length
            current_url_page = nil
          else
            link_header = LinkHeader.parse(rest_response.headers[:link])
            
            link_header_next_link = link_header.find_link(['rel', 'next'])
            current_url_page = link_header_next_link ? link_header_next_link.href : nil

            # If we are in the first round, then we want to find out (estimate) the total number of items that will be processed for the given @url
            if first_round
              link_header_last_link_url = link_header.find_link(['rel', 'last']).href
              last_link_page_index = /.*?page=(?<page_index>.+).*/.match(link_header_last_link_url)[:page_index].to_i
              
              # When there is no link page index or when there is only one page, then ...
              if last_link_page_index.nil? or last_link_page_index == 1
                  progress_bar.total = rest_response_data.length

              # Otherwise, we make an estimate; it is not the total truth because do not consider the elements in the last page
              else
                progress_bar.total = (last_link_page_index-1) * rest_response_data.length
              end

              first_round = false
            end
          end
          
          rest_response_data.each do | resource_hash |
            @processing_chain.process(resource_hash, { processing_action: Lanalytics::Processing::ProcessingAction::CREATE })
            progress_bar.increment unless progress_bar.finished?
          end

        end while current_url_page
      end

      def self.process(url, processing_steps)
        rest_processing = self.new(url, processing_steps)
        rest_processing.process
      end

      private
      def create_progress_bar
        return ProgressBar.create(title: "Syncing from #{@url}", format: '%p%% %t (%c/%C) |%b>>%i| %a', starting_at: 0, total: nil)
      end
    end
  end
end