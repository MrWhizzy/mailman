# From https://github.com/mikel/mail/blob/master/spec/spec_helper.rb#L192

class MockIMAPFetchData
  attr_reader :attr, :number

  def initialize(rfc822, number)
    @attr = { 'RFC822' => rfc822 }
    @number = number
  end
end

class MockIMAP
  @@connection = false
  @@mailbox = nil
  @@marked_for_deletion = []

  def self.examples
    @@examples
  end

  def initialize
    @@examples = []
    2.times do |i|
      @@examples << MockIMAPFetchData.new("To: test@example.com\r\nFrom: chunky@bacon.com\r\nSubject: Hello!\r\n\r\nemail message\r\ntest#{i}", i)
    end
  end

  def login(_user, _password)
    @@connection = true
  end

  def disconnect
    @@connection = false
  end

  def logout
    @@connection = false
  end

  def select(mailbox)
    @@mailbox = mailbox
    block_given? ? yield(self) : self
  end

  def examine(mailbox)
    select(mailbox)
  end

  def uid_search(_keys, _charset = nil)
    [*(0..@@examples.size - 1)]
  end
  alias search uid_search

  def uid_fetch(set, _attr)
    [@@examples[set]]
  end
  alias fetch uid_fetch

  def uid_store(set, attr, flags)
    if attr == '+FLAGS' && flags.include?(Net::IMAP::SEEN)
      @@marked_for_deletion << set
    end
  end
  alias store uid_store

  def expunge
    @@marked_for_deletion.reverse_each do |i| # start with highest index first
      @@examples.delete_at(i)
    end
    @@marked_for_deletion = []
  end

  # test only
  def self.mailbox
    @@mailbox
  end

  def self.disconnected?
    @@connection == false
  end

  def disconnected?
    @@connection == false
  end
end

require 'net/imap'
class Net::IMAP
  def self.new(*_args)
    MockIMAP.new
  end
end
