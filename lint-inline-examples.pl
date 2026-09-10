#!/usr/bin/env perl
#
# ABSTRACT: find all the <sourcecode> elements in the draft, and
# validate them against the schema
#
use File::Glob qw(:bsd_glob);
use XML::LibXML;
use File::Spec;
use File::Basename qw(dirname basename);
use common::sense;

my $xsd_file = bsd_glob(File::Spec->catfile(dirname(__FILE__), qw(deleg-*.xsd)));
my $xsd = XML::LibXML::Schema->new(location => $xsd_file);
my $doc = XML::LibXML->load_xml(location => File::Spec->catfile(dirname(__FILE__), qw(draft.xml.in)));
my $errcount = 0;

foreach my $xml (
    grep    { length > 0 }                          # filter out empty nodes
    map     { s/^\s+//sg ; s/\s+$//sg ; $_ }        # remove trailing/leading whitespace
    map     { $_->textContent }                     # convert node element to text
    grep    { q{xml} eq $_->getAttribute(q{type}) } # exclude non-XML <sourcecode> elements
    $doc->getElementsByTagName(q{sourcecode})       # get all <sourcecode> elements
) {

    eval {
        $xsd->validate(XML::LibXML->load_xml(
            string =>   sprintf(
                            '<deleg:infData xmlns:deleg="urn:ietf:params:xml:ns:epp:%s">',
                            basename($xsd_file, q{.xsd})
                        )
                        . $xml
                        . '</deleg:infData>'
        ));
    };

    if ($@) {
        say $xml;
        say $@;
        $errcount++;
    }
}

printf(STDERR qq{found %u errors\n}, $errcount);

exit($errcount);
