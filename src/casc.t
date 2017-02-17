#!/usr/bin/perl -w


my @module = ('CASC::Utilities', 'CASC::System', 'CASC::Reporting', 'CASC::Parsing');
use Test::More tests => 4;
for my $module (@module) {
    require_ok $module or BAIL_OUT "Can't load $module";
}
