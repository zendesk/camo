require 'rack'

class BasicAuthServer
  def call(_env)
    # Always return 401 with WWW-Authenticate header to simulate basic auth requirement
    [
      401,
      {
        'Content-Type' => 'text/html',
        'WWW-Authenticate' => 'Basic realm="Test Realm"'
      },
      ['Unauthorized']
    ]
  end
end

run BasicAuthServer.new
