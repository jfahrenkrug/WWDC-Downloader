# WWDC 2012 Sample Code Downloader

This script will download all the session material for you if you are a WWDC 2012 attendee.
You'll need ruby and the `mechanize`, `highline` and `json` ruby gems. You can install them like this:

    sudo gem install mechanize json highline

You simply run the script like this: 

    ruby wwdcdownloader.rb <your Apple ID> [<target-dir>]

The script will create a directory called "wwdc2012-assets" (or <target-dir> if given) in the directory you run the script from.

That's it. Enjoy and see you next year.
