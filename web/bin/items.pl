
=begin comment

This code is used to list and manipulate mht (mh table) items.

  http://localhost:8080/bin/items.pl

=cut

use strict;
$^W = 0;                        # Avoid redefined sub msgs

return &web_items_list();


use vars '$web_item_file_name'; # Avoid my, so we can keep the same name between web calls
my (@file_data);

sub web_items_list {

                                # Create header and 'add an item' form
    my $html = &html_header('Items Menu');
    $html  = qq|
<HTML><HEAD><TITLE>Items Menu</TITLE></HEAD><BODY>\n<a name='Top'></a>$html
Use this page to review or update your .mht file.|;
    $html .= qq|<br><font color=red><b>Read-Only</b>: <a href="/bin/SET_PASSWORD">Login as admin</a> to edit</font>| unless $Authorized eq 'admin';
    $html .= qq|A backup is made and comments and record order are preserved.
To update existing items, enter/change the field and hit Enter.| if $Authorized eq 'admin';
    $html .= qq|

<script>
function openparmhelp(parm1){
  window.open("RUN;&web_item_help('" + parm1 + "')","help","width=200,height=200,left=0,top=0,scrollbars=1,resizable=0")
}
</script>
|;

                                # Find files
    my (@file_paths);
    for my $file_dir (@Code_Dirs) {
        opendir(DIR, $file_dir) or die "Error, can not open directory $file_dir.\n";
        my @files = readdir(DIR);
        close DIR;
        for my $member (sort @files) {
            push @file_paths, "$file_dir/$member" if $member =~ /\.mht$/;
        }
    }

    $web_item_file_name = @file_paths[0] unless $web_item_file_name;  # Default
    $web_item_file_name = $1 if $ARGV[0] =~ /^file=(\S+)/;

                                # Create a form to pick which file
    $html .= "<table border><tr><form action=/bin/items.pl method=post><td>Which .mht file to edit?\n";
    $html .= &html_form_select('file', 1, $web_item_file_name, @file_paths) . "</td></form></tr>\n";

                                # Create form to add an item
    my $form_type =
      &html_form_select('type', 0, 'X10 Light (X10I)',
                        'X10 Appliance (X10A)', 'X10 Light (X10I)', 'X10 Ote (X10O)',
                        'X10 SwitchLinc (X10SL)', 'X10 Garage Door (X10G)', 'X10 Irrigation (X10S)',
                        'X10 RCS (X10T)',  'X10 Motion Sensor (X10MS)',
                        'EIB Switch (EIB1)', 'EIB Switch Group (EIB1G)', 'EIB Dimmer (EIB2)', 'EIB Value (EIB5)', 'EIB Drive (EIB7)',
                        qw(SERIAL VOICE IBUTTON  GENERIC COMPOOL MP3PLAYER AUDIOTRON WEATHER SG485LCD SG485RCSTHRM STARGATEDIN STARGATEVAR STARGATEFLAG STARGATERELAY STARGATETHERM STARGATEPHONE XANTECH));

#form action='/bin/items.pl?add' method=post>
    $html .= qq|<tr>
<form action='/bin/set_func.pl' method=post><td>
<input type=submit value='Create'>
<input name='func' value="web_item_add"  type='hidden'>
<input name='resp' value="/bin/items.pl" type='hidden'>
$form_type
<input type=input name=address  size=10 value='A1'>
<input type=input name=name     size=10 value='Test_light'>
<input type=input name=group    size=10 value=''>
<input type=input name=other1   size=10 value=''>
<input type=input name=other2   size=10 value=''>
<td></form><tr>
| if $Authorized eq 'admin';

                                # Parse table data
    undef @file_data;
    @file_data = &file_read($web_item_file_name);
    my %item_pos;
    my $pos = 0;
    for my $record (@file_data) {
                                # Do not list comments
        unless ($record =~ /^\s*\#/ or $record =~ /^\s*$/ or $record =~ /^Format *=/) {
            my(@item_info) = split(',\s*', $record);
            my $type = shift @item_info;
            push @{$item_pos{$type}}, $pos;
        }
        $pos++;
    }
                                # Add an index
    $html .="<tr><td><a href=/bin/items.pl?file=$web_item_file_name>Refresh</a>\n";
    $html .= "&nbsp;&nbsp;<a href=/RUN;/bin/items.pl?Reload_code>ReLoad Code</a>&nbsp;\n";
    $html .= "<B>Item Index: <B>\n";
    for my $type (sort keys %item_pos) {
        $html .= "<a href='#$type'>$type</a>\n";
    }
    $html .= "</td></tr></table>\n";

                                # Define fields by type
    my %headers = ( X10A    => [qw(Address Name Groups Interface)],
                    X10I    => [qw(Address Name Groups Interface X10_Type)],
                    X10MS   => [qw(Address Name Groups Type)],
                    GENERIC => [qw(Name Groups)],
                    SERIAL  => [qw(String Name Groups State Port)],
                    IBUTTON => [qw(ID Name Port Channel)],
                    VOICE   => [qw(Item Phrase)],
                    EIB1    => ['Address', 'Name', 'Groups', 'Mode'],
                    EIB1G    => ['Address', 'Name', 'Groups', 'Addresses'],
                    EIB2    => ['Address', 'Name', 'Groups'],
                    EIB5    => [qw(Address Name Groups Mode)],
                    EIB7    => ['Address', 'Name', 'Groups'],
                    default => [qw(Address Name Groups Other)] );

                                # Sort in type order
    for my $type (sort keys %item_pos) {

        my @headers = ($headers{$type}) ? @{$headers{$type}} : @{$headers{default}};
        my $headers = 1 + @headers;

        $html .= "<table border><tr><td colspan=$headers><B>$type</B>\n";
        $html .= "(<a name='$type' href='#Top'>back to top</a>)</td></tr>\n";

        $html .= "<tr>";
        for my $header ('', 'Type', @headers) {
            $html .= qq[<td><a href="javascript:openparmhelp('$header')">$header</a></td>];
#           $html .= "<td>$header</td> ";
        }
        $html .="</tr>\n";

        for my $pos (@{$item_pos{$type}}) {
            my $record = $file_data[$pos];
            my @item_info = split(',\s*', $record, $headers);

            $html .= "<tr>";
            $html .= "<td>";
            $html .= "<a href=/SUB;/bin/items.pl?web_item_copy($pos)>Copy</a>" if $Authorized eq 'admin';
            $html .= "    <a href=/SUB;/bin/items.pl?web_item_delete($pos)>Delete</a>" if $Authorized eq 'admin';
            $html .= "</td> ";
            $html .= "<td>$item_info[0]</td> ";
            for my $field (1 .. $headers - 1) {
                $html .= &html_form_input_set_func('web_item_set_field', "/bin/items.pl", "$pos,$field", $item_info[$field]);
            }
            $html .= "</tr>\n";
        }
        $html .= "</table>\n";

    }
    return &html_page('', $html);
}

sub web_item_set_field {
    my ($pos_field, $data) = @_;
    return &html_page('', 'Not authorized to make updates') unless $Authorized eq 'admin';
    my ($pos, $field) = $pos_field =~ /(\d+),(\d+)/;

    my $record = @file_data[$pos];

    my @item_info = split(',\s*', $record);
    $item_info[$field] = $data;

    $record = '';
    while (@item_info) {
        my $item = shift @item_info;
        $item .= ', ' if @item_info;
        $record .= sprintf("%-20s", $item);
    }

    $file_data[$pos] = $record;
#   print "db2 p=$pos f=$field d=$data r=$record\n";

    &mht_item_file_write($web_item_file_name, \@file_data);
    return 0;
}

sub web_item_copy {
    my ($pos) = @_;
    return &html_page('', 'Not authorized to make updates') unless $Authorized eq 'admin';
    my $pos2 = @file_data;
    $file_data[$pos2] = $file_data[$pos];
#   print "db copy $pos to $pos2: $file_data[$pos2]\n";
    &mht_item_file_write($web_item_file_name, \@file_data);
    return &http_redirect('/bin/items.pl');
}

sub web_item_delete {
    my ($pos) = @_;
    return &html_page('', 'Not authorized to make updates') unless $Authorized eq 'admin';
    my $pos2 = @file_data;
    $file_data[$pos] = '';
    &mht_item_file_write($web_item_file_name, \@file_data);
    return &http_redirect('/bin/items.pl');
}

sub web_item_add {
    my (@parms) = @_;
                                # Allow un-authorized users to browse only (if listed in password_allow)
    return &html_page('', 'Not authorized to make updates') unless $Authorized eq 'admin';

                                # Process form
    if (@parms) {
        my $record;
        for my $p (@parms) {
            $p =~ s/.+ \((\S+)\)/$1/;  # Change 'X10 Light (X10I)'  to X10I
            $p =~ s/ +/_/g;            # Blanks not allowed?
            $record .= "$p,  ";
#            print "db p=$p\n";
        }
#       print "db r=$record\n";
        $file_data[@file_data] = $record;
        &mht_item_file_write($web_item_file_name, \@file_data);
    }
    return 0;
}

sub web_item_help {
    my ($field) = @_;

    my %help = (Type    => 'Type of object',
                Address => 'The address of this item',
                Addresses => 'The addresses of the group members',
                Name    => 'The name of the object (without the leading $)',
                Groups  => 'List of groups the item belongs to, seperated by |',
                Interface => 'The X10 Interface to use (e.g. CM17, CM11)',
                X10_Type    => 'The type of X10 device (e.g. LM14 or preset)',
                String  => 'The serial characters to match (e.g. XA1A1 to match 2 A1 button pushes)',
                State   => 'The state name to correlate to this items serial String',
                Port    => 'Which port to look for the serial data on',
                ID      => 'Ibutton ID:  type|serial|crc  crc is optional.  type=01 (1990) type=10 (1820)',
                Channel => 'When using a switch, choose channel A or B',
                Item    => 'Item name to tie this voice command to',
                Phrase  => 'Voice_Cmd Text',
                Mode    => '\'R\' (readable): generate read request to learn current state at initialization',
                Other   => 'Other stuff :)');

    my $help = $help{$field};

    return $help;

}