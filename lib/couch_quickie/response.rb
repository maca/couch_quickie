class Response < Array
  attr_reader :offset, :key
  
  def initialize( response )
    super response['rows'].collect{ |doc| doc['value'] }
    @offset = response['offset']
    @key    = response['key']
  end
  
  def sort_by( key )
    sort{ |a,b| a[key] <=> b[key] }
  end
  
  def self.parse( response )
    return response if response.kind_of? String
    new response
  end
end