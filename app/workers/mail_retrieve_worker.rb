require 'net/imap'

GMAIL_USERNAME = 'xxxxxx@gmail.com'
GMAIL_PW = 'xxxxxxx'

class MailRetrieveWorker
  include Sidekiq::Worker

  def perform(mail_uid)

    p "-------- processing in mail worker"

    @imap = Net::IMAP.new("imap.googlemail.com", 993, true)
    @imap.login(GMAIL_USERNAME, GMAIL_PW)
    @imap.select("INBOX")

    headers = @imap.uid_fetch(mail_uid, "ENVELOPE")
    # p "------ #{headers.inspect}"
    sender = headers[0].attr['ENVELOPE']['sender'][0]
    sender_address = sender['mailbox'] + "@" + sender['host']
    p "------ sender_address: #{sender_address.inspect}"

    body = @imap.uid_fetch(mail_uid, "RFC822.TEXT")[0]
    p "------ raw body: #{body.inspect}"


    ######### TBD #######
    # use sender_address to filter wanted sender
    # parse body to get content that you care about
    # retreive database to get related info
    # call mailer to sender new email

    #####################
    # for production usage, need to config as daemon thread
  end
end
