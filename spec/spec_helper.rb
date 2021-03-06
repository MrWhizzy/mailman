$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'fileutils'
require 'mailman'
require 'rspec'
require 'maildir'
require 'simplecov'

SimpleCov.start 'rails' do
  add_filter '/bin/'
  add_filter '/db/'
  add_filter '/spec/' # for rspec
  add_filter '/test/' # for minitest
end

# Require all files in spec/support (Mocks, helpers, etc.)
Dir[File.join(File.dirname(__FILE__), 'support', '**', '*.rb')].each do |f|
  require File.expand_path(f)
end

SPEC_ROOT = File.join(File.dirname(__FILE__)) unless defined?(SPEC_ROOT)

unless defined?(THREAD_TIMING)
  THREAD_TIMING = (ENV['THREAD_TIMING'] || (defined?(RUBY_ENGINE) && (RUBY_ENGINE == 'jruby' || RUBY_ENGINE == 'rbx') ? 2.5 : 2)).to_f
end

module Mailman::SpecHelpers
  def header_matcher(pattern)
    Mailman::Route::HeaderMatcher.new(pattern)
  end

  def regexp_matcher(pattern)
    Mailman::Route::RegexpMatcher.new(pattern)
  end

  def string_matcher(pattern)
    Mailman::Route::StringMatcher.new(pattern)
  end

  def basic_message
    Mail.new("To: test@example.com\r\nFrom: chunky@bacon.com\r\nCC: testing@example.com\r\nX-Forwarded-To: Test1\r\nX-Forwarded-To: Test2\r\nSubject: Hello!\r\n\r\nemail message\r\n")
  end

  def multipart_message
    Mail.new do
      to   'test@example.com'
      from 'chunky@bacon.com'
      subject 'I am a multipart message'

      text_part do
        body 'This is plain text'
      end

      html_part do
        content_type 'text/html; charset=UTF-8'
        body '<h1>This is HTML</h1>'
      end
    end
  end

  def mailman_app(&block)
    @app = Mailman::Application.new(&block)
  end

  def send_message(message)
    @app.router.route Mail.new(message)
  end

  def config
    Mailman.config
  end

  def fixture(*name)
    File.open(File.join(SPEC_ROOT, 'fixtures', name) + '.eml').read
  end

  def setup_maildir
    maildir_path = File.join(SPEC_ROOT, 'test-maildir')
    begin
      FileUtils.rm_r(maildir_path)
    rescue StandardError
      nil
    end
    @maildir = Maildir.new(maildir_path)
    message = File.new(File.join(maildir_path, 'new', 'message1'), 'w')
    message.puts(fixture('example01'))
    message.close
  end
end

RSpec.configure do |config|
  config.include Mailman::SpecHelpers
  config.before do
    Mailman.config.logger = Logger.new(File.join(SPEC_ROOT, 'mailman-log.log'))
  end
  config.after do
    begin
      FileUtils.rm File.join(SPEC_ROOT, 'mailman-log.log')
    rescue StandardError
      nil
    end
  end
end
