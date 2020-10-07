require 'net/http'

$request_settings = { host: "http://localhost:9091"] }



# methods
def api_request(type, path, query_string, body, new_headers)
  uri = URI::HTTP.build(
    $request_settings.merge(
      path: path,
      query: query_string,
    )
  )
  req = Net::HTTP.const_get(type).new(uri, new_headers)
  req.body = body.read
  Net::HTTP.new(uri.hostname, uri.port).start {|http| http.request(req) }
end

def all_headers(response)
  header_list = {}
  response.header.each_capitalized do |k,v|
    header_list[k] =v unless k == "Transfer-Encoding"
  end
  header_list
end

def incomming_headers(request)
  request.env.map { |header, value|  [header[5..-1].split("_").map(&:capitalize).join('-'), value] if header.start_with?("HTTP_") }.compact.to_h
end

# wildcard routing
%w(get post put patch delete).each do |verb|
  WebAdminApp.send(verb, /.*/) do
    content_type $headers["Content-Type"]
    start_request = Thread.new {
      api_request(verb.capitalize, request.path_info, request.query_string, request.body, incomming_headers(request))
    }

    response = start_request.value
    status response.code
    headers all_headers(response)
    response.body
  end
end
