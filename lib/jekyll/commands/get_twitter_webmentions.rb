require 'twitter'
require 'twitter-text'
require 'json'
require 'uri'

module Jekyll
  module Commands
    class GetTwitterWebmentionsCommand < Command
      
      def self.init_with_program( prog )
        prog.command(:get_twitter_webmentions) do |c|
          c.syntax 'get_twitter_webmentions'
          c.description 'Gathers webmentions from Twitter that may not be in Brid.gy'
          
          c.action { |args, options| process args, options }
        end
      end

      def self.process( args=[], options={} )
        client = Twitter::REST::Client.new do |config|
          config.consumer_key        = ENV['TWITTER_CONSUMER_KEY']
          config.consumer_secret     = ENV['TWITTER_CONSUMER_SECRET']
        end	
        
        count = 0
        cached_incoming = Jekyll::WebmentionIO::get_cache_file_path 'incoming'
        if File.exists?(cached_incoming)
          incoming = open(cached_incoming) { |f| YAML.load(f) }
          base_url = Jekyll::WebmentionIO::jekyll_config['url']
          now = Time.now.to_date
          #client.search("#{base_url} -rt").collect do |tweet|
          client.search("@aarongustafson -rt").collect do |tweet|
            puts tweet.full_text
            puts tweet.uris.inspect
            target = nil
            tweet.uris.each do |url|
              url = url.expanded_url.to_s
              if url.include? base_url
                target = URI::parse( url.gsub("\n",'') )
                target.fragment = target.query = nil
                target = target.to_s
                break
              end
            end
        
            # if ! target
            #   next
            # end
            # target = target.sub base_url, ''
            # puts target

            html = Twitter::Autolink::auto_link( tweet.full_text )

            author = {
              :name   => tweet.user.screen_name,
              :url    => tweet.user.url,
              :photo  => tweet.user.profile_image_url
            }

            raw_webmention = {
              :source         => tweet.uri,
              :verified       => true,
              :verified_date  => now,
              :id             => tweet.id,
              :private        => false,
              :data           => {
                :author       => author,
                :url          => tweet.uri,
                :name         => nil,
                :content      => tweet.text,
                :published    => tweet.created_at,
                :published_ts => tweet.created_at
              },
              :activity       => {
                :type           => 'link',
                :sentence       => tweet.full_text,
                :sentence_html  => html
              },
              :target         => target
            }

            webmention = {
              :id       => tweet.id,
              :url      => tweet.uri,
              :source   => 'twitter',
              :pubdate  => tweet.created_at,
              :raw      => raw_webmention,
              :author   => raw_webmention[:data][:author],
              :type     => 'link',
              :content  => html
            }

            puts webmention.inspect
            
            # Make sure we have the webmention
            # if ! cached_webmentions[target][the_date].has_key? id
              
            #   webmention = ""
            #   webmention_classes = "webmention"
                    
            #   author_block = ''
            #   # puts tweet.user
            #   a_name = tweet.user.name
            #   a_url = tweet.user.url
            #   a_photo = tweet.user.profile_image_url_https
            #   if a_photo
            #     author_block << "<img class=\"webmention__author__photo u-photo\" src=\"#{a_photo}\" alt=\"\" title=\"#{a_name}\">"
            #   end
            #   name_block = "<b class=\"p-name\">#{a_name}</b>"
            #   author_block << name_block
            #   if a_url
            #     author_block = "<a class=\"u-url\" href=\"#{a_url}\">#{author_block}</a>"
            #   end
        
            #   author_block = "<div class=\"webmention__author p-author h-card\">#{author_block}</div>"
        
            #   meta_block = ""
        
            #   pubdate_iso = pubdate.strftime("%FT%T%:z")
            #   pubdate_formatted = pubdate.strftime("%-d %B %Y")
            #   published_block = "<time class=\"webmention__pubdate dt-published\" datetime=\"#{pubdate_iso}\">#{pubdate_formatted}</time>"
              
            #   meta_block << published_block
            #   meta_block << " | "
            #   meta_block << "<a class=\"webmention__source u-url\" href=\"#{permalink}\">Permalink</a>"
        
            #   meta_block = "<div class=\"webmention__meta\">#{meta_block}</div>"
              
            #   # Build the content block
            #   webmention_classes << " webmention--content-only"
              
            #   content = content.gsub(/(http[^\s]+)/, '[\1](\1)')
            #   content = Kramdown::Document.new(content).to_html
            #   if !content.start_with?('<p')
            #     content = content.sub(/^<[^>]+>/, '<p>').sub(/<\/[^>]+>$/, '</p>')
            #   end
            #   content_block = "<div class=\"webmention__content p-content\">#{content}</div>"
        
            #   # meta
            #   content_block << meta_block
                
            #   # put it together
            #   webmention << "<li id=\"webmention-#{id}\" class=\"webmentions__item\">"
            #   webmention << "<article class=\"h-cite #{webmention_classes}\">"
            #   webmention << author_block
            #   webmention << content_block
            #   webmention << "</article></li>"
        
            #   cached_webmentions[target][the_date][id] = webmention
              
            #   count += 1
            # end
        
          end
        
          if count > 0
            # File.open(cached_outgoing, 'w') { |f| YAML.dump(outgoing, f) }
          end
          Jekyll::WebmentionIO::log 'info', "#{count} Twitter webmebmentions added."
        end # file exists (outgoing)
      end # def process
    end # GetTwitterWebmentionsCommand
  end # Commands
end # Jekyll