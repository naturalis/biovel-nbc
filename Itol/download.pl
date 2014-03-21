use strict;
use HTTP::Request::Common;
use LWP::UserAgent;
use Pod::Usage;
use Data::Dumper;

#This is example code stripped out from ITol_downloader.pl obtained from http://itol.embl.de/help/iTOL_batch.zip
#Main purpose here is to strip out the minimum required to upload a file

my $download_url = "http://itol.embl.de/batch_downloader.cgi";

my $outFile = "C:/Biovel/hackathon/Christian/test.pdf";

my %post_content;
$post_content{'format'} = 'pdf';
#$post_content{'tree'} = "6250235351762113954057630"; #this one works
$post_content{'tree'} = "6250235353002613954174740";
$post_content{'displayMode'} = "circular";
#$post_content{'inverted'} = "1";
#$post_content{'arc'} = "360"; 
#$post_content{'rotation'} = "70";


#submit the data
my $ua  = LWP::UserAgent->new();
$ua->agent("iTOLbatchDownloader1.0");
my $req = POST $download_url, Content_Type => 'form-data', Content => [ %post_content ];
my $response = $ua->request($req);
if ($response->is_success()) {
  #check for the content type
  #if text/html, there was an error
  #otherwise dump the results into the outfile
  if ($response->header("Content-type") =~ /text\/html/) {
	my @res = split(/\n/, $response->content);
	print "Export failed. iTOL returned the following error message:\n\n$res[0]\n\n";
	exit;
  } else {
	open (OUT, ">$outFile") or die "Cannot write to $outFile";
	binmode OUT;
	print OUT $response->content;
	print "Exported tree saved to $outFile\n";

	# print join("\n", @res);
  }
} else {
	print "iTOL returned a web server error. Full message follows:\n\n";
	print $response->as_string;
}
