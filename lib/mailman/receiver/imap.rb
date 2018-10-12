require 'net/imap'

module Mailman
  module Receiver
    # Receives messages using IMAP, and passes them to a {MessageProcessor}.
    class IMAP
      # @return [Net::IMAP] the IMAP connection
      attr_reader :connection

      # @param [Hash] options the receiver options
      # @option options [MessageProcessor] :processor the processor to pass new
      #   messages to
      # @option options [String] :server the server to connect to
      # @option options [Integer] :port the port to connect to
      # @option options [Boolean,Hash] :ssl if options is true, then an attempt will
      #   be made to use SSL (now TLS) to connect to the server. A Hash can be used
      #   to enable ssl and supply SSL context options.
      # @option options [Boolean] :starttls use STARTTLS command to start
      #   TLS session.
      # @option options [String] :username the username to authenticate with
      # @option options [String] :password the password to authenticate with
      # @option options [String] :folder the mail folder to search
      # @option options [Array] :done_flags the flags to add to messages that
      #   have been processed
      # @option options [String] :filter the search filter to use to select
      #   messages to process
      # @option options [Boolean] :idle if true, IMAP IDLE will be used
      # @option options [Integer] :idle_timeout the maximum timeout before
      #   returning from IDLE.
      # @option options [Boolean] :persistent if true, unlimited reconnect attempts 
      #   will be made to the server, if the connection drops for any reason.
      def initialize(options)
        @processor    = options[:processor]
        @server       = options[:server]
        @port         = options[:port] || (@ssl ? 993 : 143)
        @ssl          = options[:ssl] || false
        @starttls     = options[:starttls] || false
        @username     = options[:username]
        @password     = options[:password]
        @folder       = options[:folder] || 'INBOX'
        @done_flags   = options[:done_flags] || [Net::IMAP::SEEN]
        @filter       = options[:filter] || 'UNSEEN'
        @idle         = options[:idle] || false
        @idle_timeout = options[:idle_timeout] || 60
        @persistent   = options[:persistent] || false

        if @starttls && @ssl
          raise StandardError, 'either specify ssl or starttls, not both'
        end
      end

      # Connects to the IMAP server.
      def connect
        tries ||= 5
        if @connection.nil? || @connection.disconnected?
          @connection = Net::IMAP.new(@server, port: @port, ssl: @ssl)
          @connection.starttls if @starttls
          @connection.login(@username, @password)
        end
        @connection.select(@folder)
      rescue Net::IMAP::ByeResponseError, Net::IMAP::NoResponseError, SocketError
        sleep 5
        retry unless (tries -= 1).zero? && !@persistent
      end

      # Disconnects from the IMAP server.
      def disconnect
        return false if @connection.nil?

        @connection.logout
        begin
          @connection.disconnected? ? true : @connection.disconnect
        rescue StandardError
          nil
        end
      end

      # Iterates through new messages, passing them to the processor, and
      # flagging them as done.
      def get_messages
        @connection.search(@filter).each do |message|
          body = @connection.fetch(message, 'RFC822')[0].attr['RFC822']
          begin
            @processor.process(body)
          rescue StandardError => error
            Mailman.logger.error "Error encountered processing message: #{message.inspect}\n #{error.class}: #{error.message}\n #{error.backtrace.join("\n")}"
            next
          end
          @connection.store(message, '+FLAGS', @done_flags)
        end
        # Clears messages that have the Deleted flag set
        @connection.expunge
      end

      def started?
        !(!@connection.nil? && @connection.disconnected?)
      end

      def idle
        @connection.idle(@idle_timeout) do |resp|
          # You'll get all the things from the server. For new emails (EXISTS)
          if resp.is_a?(Net::IMAP::UntaggedResponse) && (resp.name == 'EXISTS')

            # Got something. Send DONE. This breaks you out of the blocking call
            @connection.idle_done
          end
        end
      end

      def idle_done
        @connection.idle_done
      end
    end
  end
end
