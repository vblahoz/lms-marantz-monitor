package Slim::Plugin::MarantzMonitor::Plugin;

use strict;

use IO::Socket;

use Slim::Utils::Log;
use Slim::Control::Request;

use LWP::Simple;
use HTTP::Request ();
use LWP::UserAgent;
use XML::Simple;
use Data::Dumper;

my $marantzIP = "192.168.1.6";
my $marantzCommandUrl = "/MainZone/index.put.asp";

my $log = Slim::Utils::Log->addLogCategory( {
	category     => 'plugin.playMonitor',
	defaultLevel => 'DEBUG',
	description  => getDisplayName(),
});

sub getFunctions {
	return '';
}

sub getDisplayName {
	return 'PLUGIN_MARANTZ_MONITOR';
}


sub initPlugin {
	$log->debug("initPlugin");

	# Subscribe to play events
	Slim::Control::Request::subscribe(
		\&playCallback,
		[['play']]
	);

    # Subscribe to power events
    Slim::Control::Request::subscribe(
		\&powerCallback,
		[['power']]
	);
}

sub shutdownPlugin {
	$log->debug("shutdownPlugin");
	Slim::Control::Request::unsubscribe( \&playCallback );
    Slim::Control::Request::unsubscribe( \&powerCallback );
}

sub powerCallback {
    my $request = shift;
    my $client = $request->client() || return;

    if($client->name() == 'Optimus' && $client->power() != '1') {
        my %marantzStatus = marantzStatus();

        if($marantzStatus{mode} eq 'Media Player') {
            turnOffMarantz();
        }
    }
}

sub playCallback {
	my $request = shift;
	my $client  = $request->client() || return;

    if($client->name() == 'Optimus' && $client->isPlaying() == '1') {
        my %marantzStatus = marantzStatus();

        if($marantzStatus{status} ne 'ON') {
            if($marantzStatus{mode} ne 'Media Player') {
                switchMarantzMode();
            } else {
                turnOnMarantz();
            }
        }
    }
}

sub turnOnMarantz {
    $log->debug("Turning ON");
    sendMarantzCommand("cmd0=PutZone_OnOff/ON")
}

sub turnOffMarantz {
    $log->debug("Turning OFF");
    sendMarantzCommand("cmd0=PutZone_OnOff/OFF")
}

sub switchMarantzMode {
    $log->debug("Switching to Media player");
    sendMarantzCommand("cmd0=PutZone_InputFunction/MPLAY")
}

sub sendMarantzCommand {
    my $url = qq{http://${\$marantzIP}${\$marantzCommandUrl}};
    my $header = ['Content-Type' => 'text/html'];

    my $data = shift;

    my $r = HTTP::Request->new('POST', $url, $header, $data);
    my $ua = LWP::UserAgent->new();
    $ua->request($r);
}

sub marantzStatus {
    my $url = qq{http://${\$marantzIP}/goform/formMainZone_MainZoneXml.xml};

    my $xml = get($url);

    my $dom = XMLin($xml);

    my $on = $dom->{Power}{value};
    my $mode = $dom->{InputFuncSelect}{value};

    $log->debug(qq{Marantz status: ${\$on}, Mode: ${\$mode}});

    return ('status', $on, 'mode', $mode);
}


