A simple set of scripts/units for queuing and sending messages with msmtp.

* `msmtpq` is a drop-in replacement for `msmtp` to queue an outgoing
  message. It never blocks and never actually sends messages.
* `msmtpq-flush` sends reliably queued messages.

To use:

1. Send messages with `msmtpq` instead of `msmtp`.
2. Install and enable the provided systemd units to automatically flush queued
   messages.
   
Systemd Units:

* `msmtp-queue.service` - Invokes msmtpq-flush to flush queued messages, if any.
* `msmtp-queue.timer` - Invokes msmtp-queue.service every 10 minutes. This will
  allow you to send mail while offline.
* `msmtp-queue.path` - Invokes msmtp-queue.service immediately when a message is
  queued. This is the fast-path for sending mail immediately you're online.
  
These scripts really shouldn't ever *eat* your mail although you may end up
sending the same email twice on very rare occasions. However, if you send a
message while offline, they'll only re-try once every 10 minutes.

Also note, these scripts look for/put configs/logs in non-standard directories:

* GONFIG (msmtp config): `$XDG_COFIG_HOME/msmtp/config`.
* LOG: `$XDG_LOG_HOME/msmtp.log` (`$XDG_LOG_HOME` defaults to `~/.local/log`).
* QUEUE_DIR (mail queue): `$XDG_DATA_HOME/mail.queue`.

These are defined as variables at the top of the provided scripts.

---

WHY? Because it's pretty much-bullet proof and the default scripts were NIH.
