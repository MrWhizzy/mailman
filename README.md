# Mailman [![Build Status](https://secure.travis-ci.org/MrWhizzy/mailman.png)](https://secure.travis-ci.org/MrWhizzy/mailman)

Mailman is an incoming mail processing microframework (with POP3 and Maildir
support), that works with Rails "out of the box".

This fork of mailman supports [IMAP IDLE](https://en.wikipedia.org/wiki/IMAP_IDLE), for retrieving emails instantly when they arrive in real-time.

```ruby
require 'mailman'
Mailman::Application.run do
  to 'ticket-%id%@example.org' do 
    Ticket.find(params[:id]).add_reply(message)
  end
end
```

See the [User Guide](https://github.com/MrWhizzy/mailman/blob/master/USER_GUIDE.md) for more information.

**If you'd like to maintain this gem, email jonathan@titanous.com.**

## Installation

    gem install mailman

## Compatibility

Tested on Ruby 2.5.1.

## Thanks

This project was originally sponsored by Ruby Summer of Code (2010), and
mentored by [Steven Soroka](http://github.com/ssoroka).

## Copyright

Copyright (c) 2010-2013 Jonathan Rudenberg. See LICENSE for details.
