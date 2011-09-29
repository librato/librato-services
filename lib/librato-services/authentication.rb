module Librato
  module Services
    module Authentication
      def abort(code, type, errors)
        errors = [errors] unless errors.is_a?(Hash) || errors.is_a?(Array)
        errors = {:errors => {type => errors}}.to_json
        halt(code, errors)
      end

      def auth
        @auth ||= Rack::Auth::Basic::Request.new(request.env)
      end

      def unauthorized!
        headers "WWW-Authenticate" => %(Basic Realm="Librato Services")
        abort(401, :request, "Authorization Required")
      end

      def bad_request!
        abort(400, :request, "Bad Request")
      end

      def reject!(msg = "Please use secured connection through https!")
        abort(403, :request, msg)
      end

      def authorize(username, auth_token)
        (svc_user, svc_pass) = ENV["LIBRATO_SERVICES_CREDS"].split(":")

        username == svc_user && auth_token == svc_pass
      end

      def authenticate
        reject! unless request.secure? ||
          ENV["RACK_ENV"] == "development" || ENV["RACK_ENV"] == "test"

        unauthorized! unless auth.provided?
        bad_request! unless auth.basic? && auth.credentials.length == 2
        unauthorized! unless authorize(*auth.credentials)
      end
    end
  end
end
