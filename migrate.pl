#!/usr/bin/perl

use strict;

use Getopt::Long;
use LWP::UserAgent;
use XML::Simple;
use Text::CSV;
use Data::Dumper;
use Date::Manip qw| UnixDate |;

$ENV{'PERL_LWP_SSL_VERIFY_HOSTNAME'} = 0;

my ( @input, $file_name, $input_type, $user, $pass, $url_param );

GetOptions (
                "name=s"      => \$file_name,
                "cards=s{1,}" => \@input,
                "type=s"      => \$input_type,
                "user=s"      => \$user,
                "url=s"       => \$url_param,
            );

my $num = scalar @input;

unless($num && $input_type && $user && $url_param) {
	usage();
}

print "Please enter the Version One password for $user: ";
$pass = <STDIN>;
chomp($pass);

my ( $query, $request, $result, $content, $story_data, $test_data, $task_data, $attachment_data, @row, $story_id, $id, $data, $vo_card, $file, $row, @to_attach, $test_id, $task_id, $link_data, @links, $out_file );
my ( $Jtitle, $Jid, $Jowner, $Jstatus, $Jestimate, $Jsprint, $Jdate, $Jdescription, $Jepic, $Jproduct_owner, $Jproject, $Jtype, $Jinput, $JtestStatus, $Jparent, $Jsetup, $Jexpected, $Jactual );

if($file_name) {
    $out_file = "VO-Export-".$file_name.".csv";
} else {
    $out_file = 'VO-Export.csv';
}

my $base_url = "https://www1.v1host.com/$url_param/rest-1.v1/Data/";
my $browser = LWP::UserAgent->new( protocols_allowed => [ 'https' ] );
my $xml = XML::Simple->new(SuppressEmpty => '');
my $csv = Text::CSV->new ( { binary => 1 } ) or die "Cannot use CSV: ".Text::CSV->error_diag();
my @file_header = ["Title","ID","Owner","Status","Estimate","Sprint","Create Date","Description","Epic","Product Owner","Project","Setup","Inputs","Test Status","Expected Results","Actual Results","VO Parent Card","Issue Type","Attachment 1","Attachment 2","Attachment 3","Attachment 4","Attachment 5","Link 1","Link 2","Link 3","Link 4","Link 5"];

open $file, ">:encoding(utf8)", "$out_file" or die "$out_file: $!";
$csv->column_names (@file_header);
$csv->print($file, @file_header);
print $file "\n";

foreach $vo_card ( @input ) {

    print "Working with card B-".$vo_card."\n";

    #### STORY ####
    print "Getting $input_type Data...\n";
    $story_data = &get_data( $input_type, $vo_card, $user, $pass );
    $story_id = $story_data->{Asset}{id};

    #### TESTS ####
    print "Getting Test Data...\n";
    $test_data = &get_data( 'Test', $story_id, $user, $pass );

    #### TASKS ####
    print "Getting Task Data...\n";
    $task_data = &get_data( 'Task', $story_id, $user, $pass );

    #### Map Story Data ####
    $Jtitle          = $story_data->{Asset}{Attribute}{Name}{content};
    $Jid             = $story_data->{Asset}{Attribute}{Number}{content};
    $Jowner          = $story_data->{Asset}{Attribute}{'Owners.Name'}{Value};
    $Jstatus         = $story_data->{Asset}{Attribute}{'Status.Name'}{content};
    $Jestimate       = $story_data->{Asset}{Attribute}{Estimate}{content};
    $Jdate           = '';
    $Jsprint         = $story_data->{Asset}{Attribute}{'Timebox.Name'}{content};
    $Jsprint         =~ s/Sprint //;
    $Jdescription    = $story_data->{Asset}{Attribute}{Description}{content};
    $Jdescription    = &strip_tags( $Jdescription );
    $Jepic           = $story_data->{Asset}{Attribute}{'Super.Name'}{content};
    $Jproduct_owner  = $story_data->{Asset}{Attribute}{'Customer.Name'}{content};
    $Jproject        = $story_data->{Asset}{Attribute}{'Scope.Name'}{content};
    $Jsetup          = '';
    $Jinput          = '';
    $JtestStatus     = '';
    $Jparent         = '';
    $Jtype           = 'Story';

    &write_row( $story_id, $user, $pass, $input_type );

    # Only build test rows if tests attached to card
    if( $test_data->{total} > 0 ) {

        # Handle data differently if more than one test
        if( $test_data->{total} > 1) {
            foreach my $test ( values $test_data->{Asset} ) {
                $Jtitle         = $test->{Attribute}{Name}{content};
                $Jid            = $test->{Attribute}{Number}{content};
                $Jowner         = $test->{Attribute}{'Owners.Name'}{value};
                $Jstatus        = '';
                $Jestimate      = '';
                $Jdate          = '';
                $Jdescription   = $test->{Attribute}{Description}{content};
                $Jdescription   = &strip_tags( $Jdescription );
                $Jepic          = '';
                $Jproduct_owner = '';
                $Jsetup         = '';
                $Jinput         = $test->{Attribute}{Inputs}{content};
                $Jdescription   = &strip_tags( $Jdescription );
                $JtestStatus    = $test->{Attribute}{'Status.Name'}{content};
                $Jparent        = $test->{Attribute}{'Parent.Number'}{content};
                $Jtype          = 'Test Case';

                $test_id = $test->{href};
                $test_id =~ s/^.*\///;
                $test_id = "Test:".$test_id;

                &write_row( $test_id, $user, $pass, "Test" );
            }
        } else {
            $Jtitle         = $test_data->{Asset}{Attribute}{Name}{content};
            $Jid            = $test_data->{Asset}{Attribute}{Number}{content};
            $Jowner         = $test_data->{Asset}{Attribute}{'Owners.Name'}{value};
            $Jstatus        = '';
            $Jestimate      = '';
            $Jdate          = '';
            $Jdescription   = $test_data->{Asset}{Attribute}{Description}{content};
            $Jdescription   = &strip_tags( $Jdescription );
            $Jepic          = '';
            $Jproduct_owner = '';
            $Jsetup         = '';
            $Jinput         = $test_data->{Asset}{Attribute}{Inputs}{content};
            $Jdescription   = &strip_tags( $Jdescription );
            $JtestStatus    = $test_data->{Asset}{Attribute}{'Status.Name'}{content};
            $Jparent        = $test_data->{Asset}{Attribute}{'Parent.Number'}{content};
            $Jtype          = 'Test Case';

            $test_id = $test_data->{Asset}{href};
            $test_id =~ s/^.*\///;
            $test_id = "Test:".$test_id;

            &write_row( $test_id, $user, $pass, "Test" );
        }
    }

    # Only build task rows if tasks attached to card
    if( $task_data->{total} > 0 ) {

        # Handle data differently if more than one task
        if( $task_data->{total} > 1) {
            foreach my $task ( values $task_data->{Asset} ) {
                $Jtitle         = $task->{Attribute}{Name}{content};
                $Jid            = $task->{Attribute}{Number}{content};
                $Jowner         = $task->{Attribute}{'Owners.Name'}{value};
                $Jstatus        = '';
                $Jestimate      = '';
                $Jdescription   = $task->{Attribute}{Description}{content};
                $Jdescription   = &strip_tags( $Jdescription );
                $Jepic          = '';
                $Jproduct_owner = '';
                $Jinput         = '';
                $JtestStatus    = '';
                $Jparent        = $task->{Attribute}{'Parent.Number'}{content};
                $Jtype          = 'Technical Task';

                $task_id = $task->{href};
                $task_id =~ s/^.*\///;
                $task_id = "Task:".$task_id;

                &write_row( $task_id, $user, $pass, "Task" );
            }
        } else {
            $Jtitle         = $task_data->{Asset}{Attribute}{Name}{content};
            $Jid            = $task_data->{Asset}{Attribute}{Number}{content};
            $Jowner         = $task_data->{Asset}{Attribute}{'Owners.Name'}{value};
            $Jstatus        = '';
            $Jestimate      = '';
            $Jdescription   = $task_data->{Asset}{Attribute}{Description}{content};
            $Jdescription   = &strip_tags( $Jdescription );
            $Jepic          = '';
            $Jproduct_owner = '';
            $Jinput         = '';
            $JtestStatus    = '';
            $Jparent        = $task_data->{Asset}{Attribute}{'Parent.Number'}{content};
            $Jtype          = 'Technical Task';

            $task_id = $task_data->{Asset}{href};
            $task_id =~ s/^.*\///;
            $task_id = "Task:".$task_id;

            &write_row( $task_id, $user, $pass, "Task" );
        }
    }

}

close $file;

sub get_data {
    my ( $data_type, $id, $user, $pass ) = @_;

    my $queries = {
        'Story'        => 'Story?where=Number=',
        'Test'         => 'Test?where=Parent=',
        'Task'         => 'Task?where=Parent=',
        'Attachment'   => 'Attachment?where=Asset=',
        'Link'         => 'Link?where=Asset=',
        'Defect'       => 'Defect?where=Number='
    };

    my $query = $queries->{$data_type};
    $query.= "'".$id."'";

    $request = HTTP::Request->new( GET => $base_url . $query );
    $request->authorization_basic( $user, $pass );
    $result = $browser->request( $request );
    $content = $result->content;
    $data = $xml->XMLin( $content );

    return $data;
}

sub process_attachments {
    my ( $data, $username, $password ) = @_;
    my ( @attachments, $attachment );
    my $base = "https://$username:$password\@www1.v1host.com";

    if ( $data->{total} > 0) {
        if( $data->{total} > 1 ) {
            foreach my $attach ( values $data->{Asset} ) {
                $attachment = $base . $attach->{Attribute}{Content}{content} . "/" . $attach->{Attribute}{Filename}{content};
                push (@attachments, $attachment);
            }
        } else {
            $attachment = $base . $data->{Asset}{Attribute}{Content}{content} . "/" . $data->{Asset}{Attribute}{Filename}{content};
            push (@attachments, $attachment);
        }
    }

    my $top = scalar @attachments;
    for (my $i = $top; $i < 5; $i++) {
        push (@attachments, "");
    }

    return \@attachments;

}

sub process_links {
    my ( $data, $username, $password ) = @_;
    my ( @attachments, $attachment );

    push (@attachments, "");

    if ( $data->{total} > 0) {
        if( $data->{total} > 1 ) {
            foreach my $attach ( values $data->{Asset} ) {
                $attachment = $attach->{Attribute}{URL}{content};
                push (@attachments, $attachment);
            }
        } else {
            $attachment = $data->{Asset}{Attribute}{URL}{content};
            push (@attachments, $attachment);
        }
    }

    return \@attachments;

}

sub write_row {
    my ( $parent_id, $username, $password, $type ) = @_;

    #### Attachments ####
    print "Getting $type Attachment Data...\n";
    $attachment_data = &get_data( 'Attachment', $parent_id, $user, $pass );
    @to_attach = &process_attachments( $attachment_data, $user, $pass );

    #### Links ####
    print "Getting $type Link Data...\n";
    $link_data = &get_data( 'Link', $parent_id, $user, $pass );
    @links = &process_links( $link_data, $user, $pass );

    @row = ["$Jtitle","$Jid","$Jowner","$Jstatus","$Jestimate","$Jsprint","$Jdate","$Jdescription","$Jepic","$Jproduct_owner","$Jproject","$Jsetup","$Jinput","$JtestStatus","$Jexpected","$Jactual","$Jparent","$Jtype",""];
    $csv->print($file, @row);
    $csv->print($file, @to_attach);
    $csv->print($file, @links);
    print $file "\n";

}

sub strip_tags {
    my ( $string ) = @_;

    $string =~ s/<p>|<\/p>|<span>|<\/span>|<em>|<\/em>|<strong>|<\/strong>|<ul>|<\/ul>|<li>|<\/li>//g;

    return $string;
}

sub usage {
    print @_, "\n", if @_;

    print <<__EOF__;
Exports Story or Defect data from Version One into a CSV file.

Usage: $0 --name <file name> --user <user_name> --url <url_param> --type <type> --cards <number> <number> <number> ...
    --name <file_name>  - added to csv file name for reference (optional)
    --user <user_name>  - Version One username (required)
    --url <url_param>   - Version One Company URL Parameter (required)
    --type <type>       - Story or Defect (required)
    --cards             - space delimited list of cards to export (required)

You will be prompted for your Version One password.

__EOF__

    exit 1;
}

exit();
