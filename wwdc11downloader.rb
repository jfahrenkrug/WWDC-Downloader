# Have fun. Use at your own risk.

require 'rubygems'
require 'fileutils'
require 'net/http'

begin
  require 'mechanize'
  require 'json'
  require 'highline/import'
rescue LoadError => e
  puts
  puts "You need to have the mechanize, json and highline gems installed."
  puts "Install them by running"
  puts
  puts "  gem install mechanize json highline"
  puts
  puts "or"
  puts
  puts "  sudo gem install mechanize json highline"
  puts
  exit
end

puts "WWDC 2011 Session Material Downloader"
puts "by Johannes Fahrenkrug, @jfahrenkrug, springenwerk.com"
puts "See you next year!"
puts

if ARGV.size < 1
  puts "Usage: ruby wwdc2011downloader.rb <your Apple ID> [<target-dir>]"
  exit
end

BASE_URI = 'https://developer.apple.com/wwdc/scripts/services.php?type=get_session_data'

dl_dir = if ARGV.size > 1 
  ARGV.last
else
  'wwdc2011-assets'
end

# Creates the given directory if it doesn't exist already.
def mkdir(dir)
  Dir.mkdir dir unless File.exists?(dir)
end

a = Mechanize.new

# Login
wrong_password = true

while wrong_password do
  password = ask("Enter your ADC password:  ") { |q| q.echo = "*" }
  
  a.get(BASE_URI) do |page|
    my_page = page.form_with(:name => 'appleConnectForm') do |f|
      f.theAccountName  = ARGV[0]
      f.theAccountPW = password
    end.click_button

    if my_page.body =~ /get_session_data/
      wrong_password = false
    else
      puts "Wrong password, please try again."
    end
  end
end

# create dir
mkdir(dl_dir)

# get the sessions JSON  
a.get(BASE_URI) do |page|
  res = JSON.parse(page.body)
  
  sessions = res['response']['sessions']
  
  if sessions.size > 0
    
    sessions.each do |session|
      if session['type'] == 'Session'
        title = session['title']
        session_id = session['id']
        puts "Session #{session_id} '#{title}'..."

        # get the files
        dirname = "#{dl_dir}/#{session_id}-#{title.gsub(/\/|&|!/, '')}" 
        puts "  Creating #{dirname}"
        mkdir(dirname)
        
        begin
        
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
              puts "  Sorry, this session doesn't have samplecode, cleaning up."
              begin
                Dir.delete( dirname )
              rescue
              end
            end
            
          end 
        
        rescue Mechanize::ResponseCodeError => e
          STDERR.puts "  Error retrieving list for session. Proceeding with next session (#{$!})"
          next
        end
      end
    end
  else
    print "No sessions :(.\n"
  end
end

puts "Done."


