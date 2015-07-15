# Icinga notification provider for the Pushover service

This Perl script is intended as a drop-in replacement for any notification provider. It supports per-user API key configuration.

`notify-by-pushover` is designed for [Icinga][1] + [Icinga Classic UI][2].

**note:** There is currently no support for the `flapping` notifications.

[1]: https://www.icinga.org/
[2]: https://www.icinga.org/icinga/screenshots/icinga-classic/

## Requirements
* Perl with the following modules
    - URI::Escape (URL encoding in the message)
    - LWP::UserAgent (HTTP requests to the API)
* Pushover account - https://pushover.net/

## Installation

Copy the script to your system and make sure it is executable:
```
[~]# mkdir -p /opt/monitoring; cd /opt/monitoring
[~]# wget -O notify-by-pushover https://raw.githubusercontent.com/m4rcu5/notify-by-pushover/master/notify-by-pushover.pl
[~]# chmod +x /opt/monitoring/notify-by-pushover
```

## Usage

`Usage: /opt/monitoring/notify-by-pushover --appkey|-a <key> --usrkey|-u <key> --url|-l <icinga url>`

    * `appkey|a`: aka `token` The is the application key for Icinga.
    * `usrkey|u`: The is your personal user key to switch the messages are send
    * `url|l`: The public URL to the Icinga installation used for the links

### Icinga Configuration

#### Command definition

Add the following snipped to your commands definition (for example: `/etc/icinga/objects/command-pushover.cfg`)

```
define command{
    command_name    notify-by-pushover
    command_line    /opt/monitoring/notify-by-pushover -a $_CONTACTPO_APPKEY$ -u $_CONTACTPO_USRKEY$ -l "https://monitoring.my.tld"
    }
```

_replace the URL with yours_

#### Contact definition

To actually use the notification provider as defined above, you will need to add `service_notification_commands` and/or `host_notification_commands` to your contacts configuration. As well as the `_PO_APPKEY` and `_PO_USRKEY` macro.
The default file in Icinga 1.x is `/etc/icinga/objects/contacts_icinga.cfg`

A full example of a contact definition:
```
define contact{
        contact_name                    marcus
        alias                           Marcus van Dam
        service_notification_period     24x7
        host_notification_period        24x7
        service_notification_options    w,u,c,r
        host_notification_options       d,r
        service_notification_commands   notify-by-pushover,notify-service-by-email
        host_notification_commands      notify-by-pushover,notify-host-by-email
        email                           marcus@marcusvandam.nl
        _PO_APPKEY                      azyPFLWychpboBVkb2Rw3VGbYeYU4q
        _PO_USRKEY                      XxXxXxXxXxXxXxXxXxXxXxXxXxXxXx
        }
```

**Note:** Feel free to use the same `_PO_APPKEY` as in the example. This is the public Icinga app at the Pushover API (taking care of the name and icon to display).

## Authors

- Marcus van Dam (marcus _at_ marcusvandam.nl)
