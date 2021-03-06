class Response < Array
  attr_reader :offset, :key
  
  def initialize( response )
    super response['rows'].collect{ |doc| doc['value'] }
    @offset, @key = response['offset'], response['key']
  end

  def self.wrap( response )
    return response if response.kind_of? String
    new response
  end
end