# frozen_string_literal: true

require "websocket-client-simple"
require "json"

module Xtb
  module Api
    # Xtb::Api::Auth is a class that handles authentication with the xStation Trading API via WebSocket.
    # It provides a `connect` class method that takes a user ID, password, and WebSocket URL, and establishes a
    # connection with the API. The `connect` method listens for user input from standard input, and sends
    # it to the API via the WebSocket connection. The class also defines two private class methods: `websocket_connection`
    # and `websocket_message`, which are used to set up the WebSocket connection and handle incoming messages, respectively.
    # Both methods are private, as they are not intended to be used directly by clients of the `Xtb::Api::Auth` class.
    #
    # Example usage:
    #   Xtb::Api::Auth.connect("user123", "password123", "wss://ws.xtb.com/real")
    class Auth
      def self.connect(user_id, password, url)
        websocket = WebSocket::Client::Simple.connect(url)

        websocket_connection(websocket, user_id, password)
        websocket_message(websocket)

        loop do
          websocket.send $stdin.gets&.strip
        end
      end

      private_class_method def self.websocket_connection(websocket, user_id, password)
        websocket.on :open do
          auth_request = {
            "command" => "login",
            "arguments" => {
              "userId" => user_id,
              "password" => password,
              "appName" => "web"
            }
          }
          websocket.send(JSON.generate(auth_request))
        end
      end

      private_class_method def self.websocket_message(websocket)
        websocket.on :message do |msg|
          json = JSON.parse(msg.data)
          if json["status"] && json.key?("streamSessionId")
            puts "Connection established! StreamSessionId: #{json["streamSessionId"]}"
          else
            puts "Error: {#{json["errorDescr"]}}"
          end
        end
      end
    end
  end
end
