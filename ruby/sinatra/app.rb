require 'sinatra'
require 'json'

set :bind, '0.0.0.0'
set :port, 4567

get '/health' do
  content_type :json
  { status: 'ok' }.to_json
end

get '/' do
  content_type :json
  { message: 'Welcome to the API' }.to_json
end
