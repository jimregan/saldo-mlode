#!/usr/bin/perl

use warnings;
use strict;
use utf8;

use URI::Escape;

#https://svn.spraakdata.gu.se/sb-arkiv/pub/lmf/saldo/saldo.xml
#http://spraakbanken.gu.se/eng/resources

open (OUT, ">", "saldo.ttl");
open (TMP, ">", "saldo-tmp-sense-entry.ttl");
open (IN, "<", "saldo.xml");

binmode(OUT, ":encoding(utf8)");
binmode(TMP, ":encoding(utf8)");
binmode(IN, ":encoding(utf8)");

#http://spraakbanken.gu.se/eng/research/saldo/tagset
my %tags = (
	"ab"  => "",
	"aba" => "",
	"abh" => "",
	"abm" => "",
	"al"  => "",
	"av"  => "",
	"ava" => "",
	"avh" => "",
	"avm" => "",
	"ie"  => "", #att: infinitive mark
	"in"  => "",
	"inm" => "",
	"kn"  => "", #conjunction
	"kna" => "",
	"knm" => "",
	"mxc" => "", #multiwords (of any category) written as a compound
	"nl"  => "",
	"nlm" => "",
	"nn"  => "",
	"nna" => "", #acronym?
	"nnh" => "", #snåret, hörning, årsåldern, åring
	"nnm" => "", #hapax: tusen sinom tusen
	"pm"  => "",
	"pma" => "",
	"pmm" => "",
	"pn"  => "",
	"pnm" => "",
	"pp"  => "",
	"ppa" => "",
	"ppm" => "",
	"sn"  => "",
	"snm" => "",
	"ssm" => "",
	"sxc" => "",
	"vb"  => "",
	"vba" => "",
	"vbm" => "",
);

my $lexcnt = 0;
my ($lexeme, $pos, $lemgram, $paradigm);
my $tag;
my $lgramenc;
my $base = 'http://dydra.com/kurzum/saldo#';
my $lemtype;
my $sensenc;

while(<IN>) {
	if (m!<feat att="([^"]*)" val="([^"]*)" />!) {
		if ($1 eq 'writtenForm') {
			$lexeme = $2;
		}
		if ($1 eq 'partOfSpeech') {
			$tag = $2;
			if (length($tag) == 3) {
				my $tagend = substr($tag, 2, 1);
				if ($tagend eq 'm') {
					$lemtype = "Phrase";
				} elsif ($tagend eq 'h' || $tagend eq 'c') {
					$lemtype = "Part";
				} else {
					$lemtype = "Word";
				}
			} else {
				$lemtype = "Word";
			}
			$pos = $tags{$tag};
		}
		if ($1 eq 'lemgram') {
			$lemgram = $2;
			$lgramenc = uri_escape_utf8($lemgram);
		}
		if ($1 eq 'paradigm') {
			$paradigm = $2;
		}
	}
	if (m!</FormRepresentation>!) {
		print OUT "<${base}lemgram-$lgramenc>\n";
		print OUT "    a lemon:$lemtype ;\n";
		print OUT "    lemon:pattern saldofm:$paradigm ;\n";
		print OUT "    FIXME:tag saldotags:$tag ;\n";
		print OUT "    lemon:form <${base}lemgram-$lgramenc-writtenForm> .\n";
		print OUT "\n";
		print OUT "<${base}lemgram-$lgramenc-writtenForm>\n";
		print OUT "    lemon:writtenRep \"$lexeme\"\@sv .\n";
		print OUT "\n";
		# This isn't right, it's an intermediate file to get the right links
		print TMP ":lexitem-$lexcnt lemon:form <${base}lemgram-$lgramenc>\n";
	}

	if (m/<LexicalEntry>/) {
		$lexcnt++;
		print TMP ":lexitem-$lexcnt\n    a lemon:LexicalEntry .\n\n";
	}

	if (m!<Sense id="([^"]*)" />!) {
		$sensenc = uri_escape_utf8($1);
		print OUT "<${base}lemgram-$lgramenc>\n";
		print OUT "    a lemon:LexicalSense .\n";
		print OUT "\n";
		print TMP ":lexitem-$lexcnt lemon:sense <${base}sense-$sensenc>\n";
	}
	if (m!<Sense id="([^"]*)">!) {
		$sensenc = uri_escape_utf8($1);
		print OUT "<${base}lemgram-$lgramenc>\n";
		print OUT "    a lemon:LexicalSense ;\n";
		print OUT "\n";
		print TMP ":lexitem-$lexcnt lemon:sense <${base}sense-$sensenc>\n";
	}
	if (m!<SenseRelation targets="([^"]*)">!) {
		my $srelenc = uri_escape_utf8($1);
		print OUT "    lemon:reference <${base}sense-$srelenc>;\n";
	}
	if (m!</Sense>!) {
		print OUT "    .";
		print OUT "\n";

	}
}

 
