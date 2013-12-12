use strict;
use warnings;
use Test::More;

BEGIN {
    plan skip_all => 'backends required' if(!-s 'thruk_local.conf' and !defined $ENV{'CATALYST_SERVER'});
    plan skip_all => 'local test only'   if defined $ENV{'CATALYST_SERVER'};
    plan skip_all => 'test skipped'      if defined $ENV{'NO_DISABLED_PLUGINS_TEST'};
    plan tests => 81;

    # enable plugin
    `cd plugins/plugins-enabled && rm -f reports2`;
    `cd plugins/plugins-enabled && ln -s ../plugins-available/reports .`;

    use lib('t');
    require TestUtils;
    import TestUtils;
}

END {
    `cd plugins/plugins-enabled && rm -f reports`;
    `cd plugins/plugins-enabled && ln -s ../plugins-available/reports2 .`;
    unlink('root/thruk/plugins/reports');
    exit(0);
}

###########################################################
# test modules
if(defined $ENV{'CATALYST_SERVER'}) {
    unshift @INC, 'plugins/plugins-available/reports/lib';
}

SKIP: {
    skip 'external tests', 1 if defined $ENV{'CATALYST_SERVER'};

    use_ok 'Thruk::Controller::reports';
};

my($hostname,$servicename) = TestUtils::get_test_service();

my $pages = [
    { url => '/thruk/cgi-bin/reports.cgi' },
    { url => '/thruk/cgi-bin/reports.cgi?action=save&report=999&name=Service%20SLA%20Report%20for%20'.$hostname.'%20-%20'.$servicename.'&template=sla_service.tt&params.sla=95&params.timeperiod=last12months&params.host='.$hostname.'&params.service='.$servicename.'&params.breakdown=months&params.unavailable=critical&params.unavailable=unknown', 'redirect' => 1, location => 'reports.cgi', like => 'This item has moved' },
    { url => '/thruk/cgi-bin/reports.cgi?report=999', like => [ '%PDF-1.4', '%%EOF' ] },
    { url => '/thruk/cgi-bin/reports.cgi?report=999&action=edit' },
    { url => '/thruk/cgi-bin/reports.cgi?report=999&action=update', 'redirect' => 1, location => 'reports.cgi', like => 'This item has moved' },
    { url => '/thruk/cgi-bin/reports.cgi?action=remove&report=999', 'redirect' => 1, location => 'reports.cgi', like => 'This item has moved' },
    { url => '/thruk/cgi-bin/reports.cgi?action=edit&report=new', like => ['Create Report'] },
];

for my $test (@{$pages}) {
    $test->{'unlike'} = [ 'internal server error', 'HASH', 'ARRAY' ] unless defined $test->{'unlike'};
    $test->{'like'}   = [ 'Reports' ]                                unless defined $test->{'like'};
    TestUtils::test_page(%{$test});
}

