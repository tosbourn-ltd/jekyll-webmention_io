# frozen_string_literal: true

require "json"

module Jekyll
  module Commands
    class WebmentionCommand < Command
      def self.init_with_program(prog)
        prog.command(:webmention) do |c|
          c.syntax "webmention"
          c.description "Sends queued webmentions"

          c.action { |args, options| process args, options }
        end
      end

      def self.process(_args = [], options = {})
        config = configuration_from_options(options)
        Jekyll::WebmentionIO.setup_caches(config)
        sent_file = Jekyll::WebmentionIO.get_cache_file_path "sent"
        if sent_file && File.exist?( sent_file )
          WebmentionIO.log "error", "Your outgoing webmentions queue needs to be upgraded. Please re-build your project."
        end
        count = 0
        cached_outgoing = Jekyll::WebmentionIO.get_cache_file_path "outgoing"
        puts cached_outgoing
        if cached_outgoing && File.exist?(cached_outgoing)
          outgoing = WebmentionIO.load_yaml(cached_outgoing)
          outgoing.each do |source, targets|
            targets.each do |target, response|
              next unless response == false

              if target.index("//").zero?
                target = "http:#{target}"
              end
              endpoint = WebmentionIO.get_webmention_endpoint(target)
              next unless endpoint

              response = WebmentionIO.webmention(source, target, endpoint)
              next unless response

              begin
                response = JSON.parse response
              rescue JSON::ParserError
                response = ""
              end
              outgoing[source][target] = response
              count += 1
            end
          end
          if count.positive?
            WebmentionIO.dump_yaml(cached_outgoing, outgoing)
          end
          WebmentionIO.log "msg", "#{count} webmentions sent."
        end # file exists (outgoing)
      end # def process
    end # WebmentionCommand
  end # Commands
end # Jekyll
