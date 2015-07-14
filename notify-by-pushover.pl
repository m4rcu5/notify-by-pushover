#!/usr/bin/perl
# nagios: -epn

# Copyright (c) 2015 Marcus van Dam <marcus@marcusvandam.nl>
# This code is licensed under the MIT License (MIT)

use strict;
use warnings;

use Getopt::Long;
use URI::Escape;
use LWP::UserAgent;

# PushOver priorities.
use constant {
    P_LOW    => -1,
    P_NORMAL => 0,
    P_HIGH   => 1,
    P_EMERG  => 2,
};

# Get keys and url.
my ($appKey, $usrKey, $url);

GetOptions(
    "appkey|a=s" => \$appKey,
    "usrkey|u=s" => \$usrKey,
    "url|l=s"    => \$url,
) or die "Usage: $0 --appkey|-a <key> --usrkey|-u <key> --url|-l <icinga url>", "\n";

die "Missing API Keys" ,"\n" unless ($appKey && $usrKey);

# Filter types.
exit unless grep(
    $ENV{ICINGA_NOTIFICATIONTYPE},
    [
        "PROBLEM",
        "RECOVERY",
        "ACKNOWLEDGEMENT"
    ]
);

my $type = $ENV{ICINGA_SERVICEATTEMPT} ? 'service' : 'host';

# Build subject and message lines.
my $subject = sprintf('%s %s Alert: %s is %s',
    $ENV{ICINGA_NOTIFICATIONTYPE},
    ucfirst($type),
    $type eq 'service' ? $ENV{ICINGA_HOSTNAME} . '/' . $ENV{ICINGA_SERVICEDESC} : $ENV{ICINGA_HOSTNAME},
    $type eq 'service' ? $ENV{ICINGA_SERVICESTATE} : $ENV{ICINGA_HOSTSTATE}
);
my $message = sprintf('%s (%s)',
    $type eq 'service' ? $ENV{ICINGA_SERVICEOUTPUT} : $ENV{ICINGA_HOSTOUTPUT},
    $ENV{ICINGA_SHORTDATETIME}
);

# Build URL link to Icinga.
my $url_desc = "Open in Icinga";
my $url_base = $url // "http://" . qx{hostname -f};

my $url_link = $type eq 'service' ?
        sprintf('%s/cgi-bin/icinga/extinfo.cgi?type=2&host=%s&service=%s',
            $url_base,
            $ENV{ICINGA_HOSTNAME},
            uri_escape($ENV{ICINGA_SERVICEDESC})
        )
    :
        sprintf('%s/cgi-bin/icinga/status.cgi?host=%s',
            $url_base,
            $ENV{ICINGA_HOSTNAME}
        );

# Map state => priority.
my %priorities = (
    WARNING     => P_NORMAL,
    UNKNOWN     => P_LOW,
    OK          => P_NORMAL,
    CRITICAL    => P_HIGH,

    UP          => P_NORMAL,
    DOWN        => P_HIGH,
    UNREACHABLE => P_LOW,
);

# Send request to PushOver API.
my $response = LWP::UserAgent->new->post(
    "https://api.pushover.net/1/messages.json",
    [
        "token"     => $appKey,
        "user"      => $usrKey,
        "message"   => $message,
        "title"     => $subject,
        "priority"  => $priorities{
            $type eq 'service' ? $ENV{ICINGA_SERVICESTATE} : $ENV{ICINGA_HOSTSTATE}
        },
        "url_title" => $url_desc,
        "url"       => $url_link,
    ]
);

# Error handling. Exit in silence.
if ($response->is_success) {
    exit (0);
} else {
    die $response->code, " - ", $response->message, "\n";
}

exit(3)
