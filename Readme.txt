This script will download all the session material for you if you are a WWDC 2011 attendee.
You'll need ruby and the mechanize and json ruby gems. You can install them like this:

sudo gem install mechanize json

You simply run the script like this: 
ruby wwdc11downloader.rb <your Apple ID> <your ADC Password> [<target-dir>]

The script will create a directory called "wwdc2011-assets" (or <target-dir> if given) in the directory you run the script from.

That's it. Enjoy and see you next year.
