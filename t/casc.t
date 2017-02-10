#!/usr/bin/perl -w


my @module = ('CASC::Utilities', 'CASC::System', 'CASC::Reporting');
use Test::More tests => 3;
for my $module (@module) {
    require_ok $module or BAIL_OUT "Can't load $module";
}
