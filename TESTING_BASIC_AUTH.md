# Testing Basic Auth Rejection

This document explains how to test the basic auth rejection functionality added to Camo.

## Overview

The `CAMO_REJECT_BASIC_AUTH` environment variable controls whether Camo rejects image URLs that require basic authentication. When set to `true`, Camo will return a 404 for:

1. URLs with embedded credentials (e.g., `http://user:pass@example.com/image.jpg`)
2. URLs where the server responds with `401 Unauthorized` and a `WWW-Authenticate` header

## Test Coverage

Three test cases have been added to `test/proxy_test.rb`:

### 1. `test_rejects_urls_with_basic_auth_credentials_when_enabled`
Tests that URLs with embedded basic auth credentials (user:pass@host) are rejected when `CAMO_REJECT_BASIC_AUTH=true`.

### 2. `test_rejects_server_requiring_basic_auth_when_enabled`
Tests that servers requiring basic authentication (returning 401 with WWW-Authenticate header) are rejected when `CAMO_REJECT_BASIC_AUTH=true`.

### 3. `test_allows_normal_images_when_reject_basic_auth_enabled`
Tests that normal images without authentication requirements continue to work when `CAMO_REJECT_BASIC_AUTH=true`.

## Test Servers

Two new test servers have been added to `test/servers/`:

### `basic_auth.ru`
A simple server that always returns `401 Unauthorized` with a `WWW-Authenticate` header, simulating a server that requires basic authentication.

### `basic_auth_image.ru`
A server that serves an image only if valid authorization is provided, otherwise returns `401 Unauthorized` with a `WWW-Authenticate` header.

## Running Tests

### Running All Tests (without basic auth rejection)
```bash
rake test
```

This runs all tests with default settings (basic auth URLs are allowed).

### Running Tests with Basic Auth Rejection Enabled

First, start the Camo server with basic auth rejection enabled:
```bash
coffee -c server.coffee
CAMO_REJECT_BASIC_AUTH=true node server.js
```

In another terminal, run the tests:
```bash
CAMO_REJECT_BASIC_AUTH=true rake test
```

### Running Only Basic Auth Tests

To run only the basic auth-related tests:
```bash
CAMO_REJECT_BASIC_AUTH=true BUNDLE_GEMFILE=test.gemfile bundle exec ruby -I test test/proxy_test.rb -n /basic_auth/
```

## Expected Behavior

### With `CAMO_REJECT_BASIC_AUTH=true`
- URLs with credentials in them: **404 Not Found**
- Servers requiring basic auth: **404 Not Found** (after HEAD request check)
- Normal images: **200 OK**

### With `CAMO_REJECT_BASIC_AUTH=false` (default)
- URLs with credentials: **Depends on server** (credentials may be forwarded)
- Servers requiring basic auth: **401 Unauthorized** (browser may show auth prompt)
- Normal images: **200 OK**

## Manual Testing

To manually test the basic auth rejection:

1. Start a test server that requires basic auth:
   ```bash
   rackup --port 9292 test/servers/basic_auth_image.ru
   ```

2. Start Camo with basic auth rejection enabled:
   ```bash
   CAMO_REJECT_BASIC_AUTH=true CAMO_KEY=test node server.js
   ```

3. Generate a camo URL for the basic auth image:
   ```ruby
   require 'openssl'
   require 'addressable/uri'
   
   image_url = "http://localhost:9292/octocat.jpg"
   key = "test"
   hexdigest = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), key, image_url)
   
   # Query string format
   uri = Addressable::URI.parse("http://localhost:8081/#{hexdigest}")
   uri.query_values = { 'url' => image_url }
   puts uri.to_s
   ```

4. Access the generated URL in your browser - you should see a 404 response instead of a basic auth prompt.

## Debugging

To see detailed logs during testing:
```bash
CAMO_REJECT_BASIC_AUTH=true CAMO_LOGGING_ENABLED=debug node server.js
```

This will show:
- When basic auth is detected in URLs
- When servers respond with 401 + WWW-Authenticate headers
- The flow of HEAD requests used to check for authentication requirements

