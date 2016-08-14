A simple set of scripts/units for queuing and sending messages with msmtp.

* `msmtpq` *always* queues outgoing messages, never blocks, and never actually
  sends them.
* `msmtpq-flush` sends all queued messages.

This means that if you just use `msmtpq`, your mail will never be sent. Instead,
you should use `msmtpq` to queue your messages and then let systemd flush them
as they're queued using the provided systemd units.

* `msmtp-queue.service` - Flushes queued mail, if any.
* `msmtp-queue.timer` - Flushes queued mail every 10m. This will allow you to
  send mail while offline.
* `msmtp-queue.path` - Flushes queued mail as it is queued. This is the
  fast-path for the case when you're currently online.
  
These scripts really shouldn't ever *eat* your mail although you may end up
sending the same email twice on very rare occasions. However, the systemd units
don't, in any way, detect whether or not you're online so, if you're offline,
they don't try sending mail for another 10m.

Also note, these scripts look for/put configs/logs in non-standard directories:

* config: `$XDG_COFIG_HOME/msmtp/config`
* log: `$XDG_LOG_HOME/msmtp.log` (`$XDG_LOG_HOME` defaults to `~/.local/log`).

---

WHY? Because it's pretty much-bullet proof and the default scripts were NIH.
