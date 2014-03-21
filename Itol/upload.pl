use strict;
use HTTP::Request::Common;
use LWP::UserAgent;
use Pod::Usage;
use Data::Dumper;

#This is example code stripped out from ITol_uploader.pl obtained from http://itol.embl.de/help/iTOL_batch.zip
#Main purpose here is to strip out the minimum required to upload a file

my $treeFile = "C:/Biovel/hackathon/Examples/ExampleTree.nex.con";
my $treeFormat = 'nexus';

my %post_content;
$post_content{'treeFile'} = [ $treeFile ]; 
$post_content{'treeFormat'} = $treeFormat;

my $upload_url = "http://itol.embl.de/batch_uploader.cgi";

my $req = POST $upload_url, Content_Type => 'form-data', Content => [ %post_content ];
my $ua  = LWP::UserAgent->new();
$ua->agent("iTOLbatchUploader1.0");
my $response = $ua->request($req);

#print Dumper $response;

my %myresponse = %{$response};
my $request = $myresponse{'_request'};
print Dumper $request;
print "\n";
print "\n";

if ($response->is_success()) {
    my @res = split(/\n/, $response->content);
	#check for an upload error
	if ($res[$#res] =~ /^ERR/) {
		print "Upload failed. iTOL returned the following error message:\n\n$res[0]\n\n";
		exit;
	}
	#upload without warnings, ID on first line
	
	if ($res[0] =~ /^SUCCESS: (\S+)/) {
		print "Upload successful. Your tree is accessible using the following iTOL tree ID:\n\n$1\n\n";
		exit;
	}
	print "Upload successful. Warnings occured during upload:\n\n";
	for (0..$#res-1) {
		print $res[$_] . "\n";
	}
	if ($res[$#res] =~ /^SUCCESS: (\S+)/) {
		print "\n\nYour tree is accessible using the following iTOL tree ID:\n\n$1\n\n";
		exit;
	} else {
		print "This shouldn't happen. iTOL did not return an error, but there is no tree ID. Please email the full dump below to letunic\@embl.de:\n\n===DEBUG DUMP==\n";
		print join("\n", @res);
		print  "===END DUMP==\n";
	}
} else {
	print "iTOL returned a web server error. Full message follows:\n\n";
	print $response->as_string;
}

exit;
