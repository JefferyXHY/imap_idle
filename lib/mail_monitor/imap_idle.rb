SERVER = 'imap.googlemail.com'
USERNAME = 'xxxxxx@gmail.com'
PW = 'xxxxx'
require 'net/imap'

require File.dirname(__FILE__) + "/../../config/environment"

# monitor gmail new email arrive and retrieve message information
# trigger sidekiq worker in rails application for further processing
# refer to: http://www.ruby-forum.com/topic/50828
# refer to: https://gist.github.com/jem/2783772
class Net::IMAP
  def idle
    cmd = "IDLE"
    synchronize do
      @idle_tag = generate_tag
      put_string(@idle_tag + " " + cmd)
      put_string(CRLF)
    end
  end

def say_done
    cmd = "DONE"
    synchronize do
      put_string(cmd)
      put_string(CRLF)
    end
  end

def await_done_confirmation
    synchronize do
      get_tagged_response(@idle_tag, nil)
      puts 'just got confirmation'
    end
  end
end

class Monitor
  attr_reader :imap

  public
  def initialize
    @imap = nil
    @mailer = nil
    start_imap
  end

  def tidy
    stop_imap
  end

  def trigger_worker(response)
    p "-------------------------------- start"
    p "------ seq num in [INBOX]: #{response.data.inspect}"
    mail_uid = @imap.fetch(response.data, "UID")[0].attr['UID']
    p "------ UID: #{mail_uid}"
    MailRetrieveWorker.perform_async(mail_uid)
    p "-------------------------------- end"
  end

  def bounce_idle
    # Bounces the idle command.
    @imap.say_done
    @imap.await_done_confirmation
    # Do a manual check, just in case things aren't working properly.
    @imap.idle
  end

  private
  def start_imap
    @imap = Net::IMAP.new(SERVER, 993, true)
    @imap.login USERNAME, PW
    @imap.select 'INBOX'

    # Add handler.
    @imap.add_response_handler do |resp|
      if resp.kind_of?(Net::IMAP::UntaggedResponse) and resp.name == "EXISTS"
        @imap.say_done
        Thread.new do
          @imap.await_done_confirmation
          trigger_worker(resp)
          @imap.idle
        end
      end
    end
    @imap.idle
  end

  def stop_imap
    @imap.done
  end
end

begin
  Net::IMAP.debug = true
  r = Monitor.new
  loop do
    puts 'bouncing...'
    r.bounce_idle
    sleep 15*60
  end
ensure
  r.tidy
end
