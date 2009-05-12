require File.dirname(__FILE__) + '/spec_helper.rb'
require File.join(FIXTURES, 'calendar')

include CouchQuickie::Mixins

describe Views do
  before do
    @calendar = JSON.parse( JSON_CALENDAR )
  end

end

