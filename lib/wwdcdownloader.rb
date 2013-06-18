# Have fun. Use at your own risk.
# Copyright (c) 2013 Johannes Fahrenkrug

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
  puts "  bundle install"
  puts
  puts "and then run the script like this:"
  puts
  puts "  bundle exec ruby lib/wwdcdownloader.rb"
  puts
  exit
end

class WWDCDownloader
  BASE_URI = 'https://developer.apple.com/wwdc-services/cy4p09ns/a4363cb15472b00287b/sessions.json'

  WWDC_LIBRARIES = [{:base => 'https://developer.apple.com/library/prerelease/ios', :lib => '/navigation/library.json'}, 
                    {:base => 'https://developer.apple.com/library/prerelease/mac', :lib => '/navigation/library.json'}]
  
  attr_accessor :downloaded_files, :dl_dir, :mech, :min_date
  
  def initialize(dl_dir, min_date)
    self.dl_dir = dl_dir
    self.min_date = min_date
    self.mech = Mechanize.new
    self.downloaded_files = []
  end

  # Creates the given directory if it doesn't exist already.
  def mkdir(dir)
    if File.exists?(dir)
      false
    else
      Dir.mkdir dir 
      true
    end
  end

  # Login
  def login
    wrong_password = true

    while wrong_password do
      password = ask("Enter your ADC password:  ") { |q| q.echo = "*" }

      if ENV['http_proxy'] || ENV['HTTP_PROXY']
        uri = (ENV['http_proxy']) ? ENV['http_proxy'] : ENV['HTTP_PROXY']
        parsedUrl = URI.parse(uri)
        self.mech.set_proxy parsedUrl.host, parsedUrl.port
      end

      self.mech.get('https://developer.apple.com/wwdc/videos/') do |page|
        my_page = page.form_with(:name => 'appleConnectForm') do |f|
          f.theAccountName  = ARGV[0]
          f.theAccountPW = password
        end.click_button

        if my_page.body =~ /incorrect/
          puts "Wrong password, please try again."
        else
          wrong_password = false
        end
      end
    end
  end
  
  def download_sample_code_from_book_json(book_json_url, code_base_url, dest_dir, duplicates_ok)
    did_download = false
    self.mech.get(book_json_url) do |book_json|
      if book_json.body[0,1] == '<'
        puts " Sorry, this samplecode apparently isn't available yet: #{code_base_url}/book.json"
      else
        book_res = JSON.parse(book_json.body)
        filename = book_res["sampleCode"]
        url = "#{code_base_url}/#{filename}"
        
        if duplicates_ok or !self.downloaded_files.include?(url)            
          # remember what we downloaded
          self.downloaded_files << url
    
          puts "  Downloading #{url}"
          begin
            self.mech.get(url) do |downloaded_file|
              open(dest_dir + "/" + filename, 'wb') do |file|
                file.write(downloaded_file.body)
              end
              did_download = true
            end
          rescue Exception => e
            puts "  Download failed #{e}"
          end
        elsif !duplicates_ok
          puts "  Already downloaded this file, skipping."
        end
      end
    end
    
    did_download
  end

  def download_sample_code_for_page(a_page_url, dest_dir, duplicates_ok = true)
    self.mech.get(a_page_url) do |page|
      has_samplecode = false
      page.links_with(:href => %r{/samplecode/} ).each do |link|            
        has_samplecode = true
        code_base_url = File.dirname(link.href)
      
        download_sample_code_from_book_json("#{code_base_url}/book.json", code_base_url, dest_dir, duplicates_ok)
      end
    
      if !has_samplecode
        puts "  Sorry, this session doesn't have samplecode, cleaning up."
        begin
          Dir.delete( dest_dir )
        rescue
        end
      end
    
    end
  end

  def load
    mkdir(dl_dir)
    
   # get the sessions JSON  
   self.mech.get(BASE_URI) do |page|
     res = JSON.parse(page.body)
   
     # Was there an error?
     error = res['response']['error']
   
     if (error)
       STDERR.puts "  Apple's API returned an error: '#{error}'"
       exit
     end
   
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
             download_sample_code_for_page(session['url'], dirname)
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
    
    # scrape the WWDC libraries... 
    puts
    puts "Scraping the WWDC libraries (not all sample code might be linked up correctly yet)"
    WWDC_LIBRARIES.each do |lib_hash|
      lib = "#{lib_hash[:base]}#{lib_hash[:lib]}"
      self.mech.get(lib) do |page|
        body = page.body.gsub("''", '""')
        res = JSON.parse(body)
        
        docs = res['documents']
        
        if docs.size > 0

          docs.each do |doc|
            if doc[2] == 5 and doc[3] >= self.min_date # sample code and newer or equal to min date
              title = doc[0]
              
              puts "Sample Code '#{title}'..."

              # get the files
              dirname = "#{dl_dir}/#{title.gsub(/\/|&|!/, '')}" 
              puts "  Creating #{dirname}"
              did_create_dir = mkdir(dirname)
              
              segments = doc[9].split('/')
              url = "#{lib_hash[:base]}/samplecode/#{segments[2]}/book.json"

              begin     
                puts url 
                did_download = download_sample_code_from_book_json(url, "#{lib_hash[:base]}/samplecode/#{segments[2]}", dirname, false)
                if !did_download and did_create_dir
                  Dir.delete( dirname )
                end
              rescue Mechanize::ResponseCodeError => e
                STDERR.puts "  Error retrieving list for sample code. Proceeding with next one (#{$!})"
                next
              end
            end
          end
        else
          print "No code samples :(.\n"
        end
      end
    end

    puts "Done."
  end
  
  def self.run!(*args)
    puts "WWDC 2013 Session Material Downloader"
    puts "by Johannes Fahrenkrug, @jfahrenkrug, springenwerk.com"
    puts "See you next year!"
    puts

    if args.size < 1
      puts "Usage: wwdcdownloader <your Apple ID> [<target-dir>]"
      exit
    end

    dl_dir = if args.size > 1 
      args.last
    else
      'wwdc2013-assets'
    end
    
    w = WWDCDownloader.new(dl_dir, '2013-06-10')
    w.login
    w.load
    return 0
  end
end