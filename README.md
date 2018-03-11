# README

1. monitor gmail new email arrive and retrieve message information
1. trigger sidekiq worker in rails application for further processing

* System dependencies
1. sidekiq
2. redis

* Configuration
1. in `imap_idle.rb`, change `USERNAME` and `PW`
2. in `mail_retrieve_worker.rb`, change `GMAIL_USERNAME` and `GMAIL_PW`

* Usage
run in development env, `RAILS_ENV=development ruby imap_idle.rb`

