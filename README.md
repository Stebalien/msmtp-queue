# A simple set of scripts/units for queuing and sending messages with msmtp.

* `msmtpq` is a drop-in replacement for `msmtp` to queue an outgoing
  message. It never blocks and never actually sends messages.
* `msmtpq-flush` sends reliably queued messages.
* `msmtpq-queue` shows information about queued messages.

## Motivation

Upstream [msmtp](https://marlam.de/msmtp/) comes with not one but _two_ different offline queue mail sending queue scripts. Unfortunately:

1. The older one is simpler and easier to understand, but also less well maintained.
2. The newer one tries to do way too much and that makes me nervous.
3. Both use lock "files" instead of advisory locks. I don't want my mail queue to get stuck any time my queue flushing process gets killed while attempting to flush the queue.
4. Neither use follow the XDG spec.
5. They don't provide systemd integration.

## Usage

1. Send messages with `msmtpq` instead of `msmtp`.
2. Install and enable the provided systemd units to automatically flush queued
   messages.
3. Use `msmtmpq-queue` to see information about the messages.
   - `-h` help / usage
   - `-c` print count of queued messages and exit
   - `-f` include the full message file path

## Systemd Units

* `msmtp-queue.service` - Invokes msmtpq-flush to flush queued messages, if any.
* `msmtp-queue.timer` - Invokes msmtp-queue.service every 10 minutes. This will
  allow you to send mail while offline.
* `msmtp-queue.path` - Invokes msmtp-queue.service immediately when a message is
  queued. This is the fast-path for sending mail immediately you're online.

These scripts really shouldn't ever *eat* your mail although you may end up
sending the same email twice on very rare occasions. However, if you send a
message while offline, they'll only re-try once every 10 minutes.

Also note, these scripts look for/put configs/logs in non-standard directories:

* LOG: `$XDG_STATE_HOME/msmtp/queue.log` (`$XDG_STATE_HOME` defaults to `~/.local/state`).
* QUEUE_DIR (mail queue): `$XDG_DATA_HOME/msmtp/queue`.

These are defined as variables at the top of the provided scripts.

## Installation

This is a highly simplified script assuming you already have the above-mentioned
msmtp config file and set up XDG variables.

```sh
git clone https://github.com/Stebalien/msmtp-queue.git /tmp/msmtpq
sudo cp /tmp/msmtpq/msmtpq* /usr/local/bin
mkdir -p ~/.config/systemd/user $XDG_DATA_HOME/mail.queue
cp /tmp/msmtpq/systemd/msmtp-queue.* ~/.config/systemd/user
systemctl --user enable msmtp-queue.path msmtp-queue.timer
```

Afterwards, update your mutt configuration to use msmtpq instead of msmtp.

# MacOS

[This fork](https://github.com/neuhalje/msmtp-queue/) maintains a MacOS/homebrew port.
