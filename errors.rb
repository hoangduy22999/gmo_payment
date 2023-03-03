module Gmo
  class Errors < StandardError
    ERROR_INFO_SEPARATOR = '|'.freeze

    private

    def error_message(info, locale)
      ::Gmo::Const::API_ERROR_MESSAGES[locale][info] || info
    end
  end

  module Payment
    class Error < ::Gmo::Errors
      attr_accessor :error_info, :response_body, :locale, :error_messages

      def initialize(response_body = '', error_info = nil)
        self.response_body = if response_body && response_body.is_a?(String)
                               response_body.strip
                             else
                               ''
                             end
        if error_info.nil?
          begin
            error_info = Rack::Utils.parse_nested_query(response_body.to_s)
          rescue StandardError
            error_info ||= {}
          end
        end
        self.error_info = error_info
        message = self.response_body
        super(message)
      end
    end

    class ServerError < Error
    end

    class APIError < Error
      def initialize(error_info = {}, locale = ::Gmo::Const::DEFAULT_LOCALE)
        self.error_info = JSON.parse(error_info)[0]
        self.locale = locale
        set_error_messages
        message = response_body
        super(message)
      end

      private

      def set_error_messages
        self.error_messages = error_info['errInfo'].to_s.split(ERROR_INFO_SEPARATOR)
                                                   .map { |e| error_message(e, locale) || e }
        self.response_body = error_messages.join(ERROR_INFO_SEPARATOR).to_s
      end
    end
  end
end
