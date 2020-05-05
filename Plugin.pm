package Plugins::PlayMonitor::Plugin;

use strict;

use IO::Socket;

use Slim::Utils::Log;
use Slim::Control::Request;

my $log = Slim::Utils::Log->addLogCategory( {
	category     => 'plugin.playMonitor',
	defaultLevel => 'ERROR',
	description  => getDisplayName(),
});

sub getFunctions {
	return '';
}

sub getDisplayName {
	return 'PLUGIN_PLAY_MONITOR';
}

sub initPlugin {
	$log->debug("initPlugin");
	# Subscribe to power events
	Slim::Control::Request::subscribe(
		\&statusCallback,
		[['status']]
	);
}

sub shutdownPlugin {
	$log->debug("shutdownPlugin");
	Slim::Control::Request::unsubscribe( \&statusCallback );
}

sub statusCallback {
	$log->debug("statusCallback");

	my $request = shift;

	$log->debug($request);

	my $client  = $request->client() || return;

	my $sock = IO::Socket::INET->new(
    Proto    => 'udp',
    PeerPort => 6500,
    PeerAddr => '192.168.1.6',
	);
	if(!$sock) {
		$log->error("Could not create socket: $!");
		return;
	}

	my $msg = $client->id() . ':' . $client->name() . ':' . $client->power();
	$log->debug($msg);
	my $rc = $sock->send($msg);
	if(!$rc) {
		$log->error("Send error: $!");
	}
}


