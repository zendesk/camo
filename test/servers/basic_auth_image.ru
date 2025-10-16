require 'rack'

class BasicAuthImageServer
  # rubocop:disable Metrics/MethodLength
  def call(env)
    # Check for Authorization header
    auth = env['HTTP_AUTHORIZATION']

    if auth && auth.start_with?('Basic ')
      # If auth is provided, serve the image
      image_path = File.join(File.dirname(__FILE__), 'octocat.jpg')
      [
        200,
        {
          'Content-Type' => 'image/jpeg',
          'Content-Length' => File.size(image_path).to_s
        },
        [File.read(image_path)]
      ]
    else
      # No auth provided, return 401
      [
        401,
        {
          'Content-Type' => 'text/html',
          'WWW-Authenticate' => 'Basic realm="Image Realm"'
        },
        ['Unauthorized']
      ]
    end
  end
  # rubocop:enable Metrics/MethodLength
end

run BasicAuthImageServer.new
