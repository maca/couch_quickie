require 'rubygems'
require 'spec'
require File.dirname(__FILE__) + '/../lib/couch_quickie'

FIXTURES = File.dirname(__FILE__) + '/fixtures'

JSON_CALENDAR = File.read( File.join(FIXTURES, 'calendar.json') )
BOOK_VIEW = File.read( File.join(FIXTURES, 'book_view.json') )


