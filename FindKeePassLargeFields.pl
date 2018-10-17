#!/bin/perl

use strict;
use warnings;

my $rc = eval
{
    require XML::LibXML;
    require XML::Hash::LX;
    require Getopt::Long;
  1;
};
if (!$rc)
{
    print "This script requires the XML::LibXML, XML::Hash::LX and Getopt::Long perl libraries.\n";
    exit;
}

use XML::LibXML;
use XML::Hash::LX;
use Getopt::Long;

my %args;
GetOptions(\%args,
           "filename=s",
) or die "Invalid arguments!";
if (! defined($args{filename})) {
    print "Usage: $0 -filename keepass.xml" unless $args{filename};
    exit;
}

if (! -f $args{filename})
{
    print $args{filename} . " doesn't exist.  Aborting.\n";
    exit;
}

# load
open my $fh, '<', $args{filename};
binmode $fh; # drop all PerlIO layers possibly created by a use open pragma
my $dom = XML::LibXML->load_xml(IO => $fh);
close $fh;

my $folder = undef;
foreach my $group ($dom->findnodes('//Group')) {
    $folder = $group->findvalue('./Name');
    foreach my $entry ($group->findnodes('./Entry')) {
        my $title = undef;
        my $entryHash = xml2hash $entry;
        foreach my $stringArray ($entryHash->{'Entry'}->{'String'})
        {
            if (ref($stringArray) ne 'ARRAY')
            {
                next;
            }
            my %stringHash;
            my $tooLargeString = undef;
            foreach my $keyValuePair (@{$stringArray}) {
                $stringHash{$keyValuePair->{'Key'}} = $keyValuePair->{'Value'};
                if (length($keyValuePair->{'Value'}) >= 10000)
                {
                    $tooLargeString = substr($keyValuePair->{'Value'}, 0, 100);
                }                   
            }
            if (defined($stringHash{'Title'}) && defined($tooLargeString))
            {
                print "'" . $stringHash{'Title'} . "' inside the '" . $folder .
                    "' folder contains a value too large to import into bitwarden: " . $tooLargeString . "\n\n";
                last;
            }
        }
    }
}


  