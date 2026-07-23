Rails.application.routes.draw do
  get "/health", to: proc { [200, { "Content-Type" => "application/json" }, ['{"status":"ok"}']] }
  root to: proc { [200, { "Content-Type" => "application/json" }, ['{"message":"Welcome to the API"}']] }
end
