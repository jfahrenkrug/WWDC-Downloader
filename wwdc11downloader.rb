# Have fun. Use at your own risk.

require 'rubygems'
require 'mechanize'
require 'json'
require 'fileutils'
require 'net/http'

puts "WWDC 2011 Session Material Downloader"
puts "by Johannes Fahrenkrug, @jfahrenkrug, springenwerk.com"
puts "See you next year!"
puts

if ARGV.size < 2
  puts "Usage: ruby wwdc2011downloader.rb <your Apple ID> <your ADC Password> [<target-dir>]"
  exit
end

base_uri = 'https://developer.apple.com/wwdc/scripts/services.php?type=get_session_data'

dl_dir = if ARGV.size > 2 
  ARGV.last
else
  'wwdc2011-assets'
end

# Creates the given directory if it doesn't exist already.
def mkdir(dir)
  Dir.mkdir dir unless File.exists?(dir)
end

# create dir
mkdir(dl_dir)

a = Mechanize.new

# Login
a.get(base_uri) do |page|
  my_page = page.form_with(:name => 'appleConnectForm') do |f|
    f.theAccountName  = ARGV[0]
    f.theAccountPW = ARGV[1]
  end.click_button
end

# get the sessions JSON  
a.get(base_uri) do |page|
  res = JSON.parse(page.body)
  
  sessions = res['response']['sessions']
  
  if sessions.size > 0
    
    sessions.each do |session|
      if session['type'] == 'Session'
        title = session['title']
        session_id = session['id']
        puts "Session '#{title}'..."

        # get the files
        dirname = "#{dl_dir}/#{session_id}-#{title.gsub(/\/|&|!/, '')}" 
        puts "  Creating #{dirname}"
        mkdir(dirname)
        a.get(session['url']) do |page|
          has_samplecode = false
          page.links_with(:href => %r{/samplecode/} ).each do |link|            
            has_samplecode = true
            code_base_url = File.dirname(link.href)
            
            a.get("#{code_base_url}/book.json") do |book_json|
              if book_json.body[0,1] == '<'
                puts " Sorry, this samplecode apparently isn't available yet: #{code_base_url}/book.json"
              else
                book_res = JSON.parse(book_json.body)
                filename = book_res["sampleCode"]
                url = "#{code_base_url}/#{filename}"
              
                puts "  Downloading #{url}"
                begin
                  a.get(url) do |downloaded_file|
                    open(dirname + "/" + filename, 'wb') do |file|
                      file.write(downloaded_file.body)
                    end
                  end
                rescue Exception => e
                  puts "  Download failed #{e}"
                end
              end
            end
          end
          
          if !has_samplecode
            puts "  Sorry, this session doesn't have samplecode."
          end
          
        end
      end
    end
  else
    print "No sessions :(.\n"
  end
end

puts "Done."


