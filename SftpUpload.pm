#! /usr/bin/env perl
###################################################
#
#  Copyright (C) 2018 Ivan Zverev <ffsjp@yandex.ru>
#
#  This file is part of Shutter.
#
#  Shutter is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 3 of the License, or
#  (at your option) any later version.
#
#  Shutter is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with Shutter; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
###################################################

package SftpUpload;

use lib $ENV{'SHUTTER_ROOT'}.'/share/shutter/resources/modules';

use utf8;
use strict;
use POSIX qw/setlocale/;
use Locale::gettext;
use Glib qw/TRUE FALSE/;
use Data::Dumper;

use Shutter::Upload::Shared;
our @ISA = qw(Shutter::Upload::Shared);

my $d = Locale::gettext->domain("shutter-plugins");
$d->dir( $ENV{'SHUTTER_INTL'} );

my %upload_plugin_info = (
    'module'                        => "SftpUpload",
    'url'                           => "http://shutter-sftp.ffsjp.ru/",
    'registration'                  => "",
    'name'                          => "SftpUpload",
    'description'                   => "Upload screenshots by sftp",
    'supports_anonymous_upload'     => TRUE,
    'supports_authorized_upload'    => TRUE,
    'supports_oauth_upload'         => FALSE,
);

binmode( STDOUT, ":utf8" );
if ( exists $upload_plugin_info{$ARGV[ 0 ]} ) {
    print $upload_plugin_info{$ARGV[ 0 ]};
    exit;
}


sub new {
    my $class = shift;
 
    #call constructor of super class (host, debug_cparam, shutter_root, gettext_object, main_gtk_window, ua)
    my $self = $class->SUPER::new( shift, shift, shift, shift, shift, shift );

    bless $self, $class;
    return $self;
}

sub init {
    my $self = shift;

    use Net::SFTP::Foreign;
    use JSON;
    use IO::File;
    use File::Basename qw(basename);

    $self->{_config} = { };
	$self->{_config_file} = $ENV{'HOME'} . '/.config/shutter-sftp.json';

    return $self->setup;
}

sub setup {
    my $self = shift;

    $self->{_config}->{host} = ''; # domain name
    $self->{_config}->{directory} = ''; # directory in remote server
    $self->{_config}->{link} = ''; # base link without last slash

    my $json;
    {
        local $/; #Enable 'slurp' mode
        open my $fh, "<", $self->{_config_file};
        $json = <$fh>;
        close $fh;
    }
    $self->{_config} = decode_json($json);

    return TRUE;
}
 
sub upload {
    my ( $self, $upload_filename, $username, $password ) = @_;

    # you can set username and password in config file
    $username = $self->{_config}->{username} || $username;
    $password = $self->{_config}->{password} || $password;

    #store as object vars
    $self->{_filename} = $upload_filename;
    $self->{_username} = $username;
    $self->{_password} = $password;
    $self->{_remote_file} = $self->{_config}->{directory} . '/' . basename($upload_filename);
    $self->{_key} = $self->{_config}->{key} || '';
    $self->{_passphrase} = $self->{_config}->{passphrase} || '';
    my $link = $self->{_config}->{link} . '/' . basename($upload_filename);
 
    utf8::encode $upload_filename;
    utf8::encode $password;
    utf8::encode $username;

    my %ssh_opts = (
        'user' => $username,
    );

    if( $password ne "" ) {
        $ssh_opts{'password'} = $password;
    }
    if( $self->{_key} ne "" ) {
        $ssh_opts{'key_path'} = $self->{_key};
    }
    if( $self->{_passphrase} ne "" ) {
        $ssh_opts{'passphrase'} = $self->{_passphrase};
    }

    if ( $username ne "" ) {

        eval{
            $self->{_links}{'status'} = 200;
            $self->{_sftp} = Net::SFTP::Foreign->new($self->{_config}->{host}, %ssh_opts);

            unless( $self->{_sftp} ){
                $self->{_links}{'status'} = 999;
            }

            unless( $self->{_sftp}->put($upload_filename, $self->{_remote_file}) ) {
                $self->{_links}{'status'} = 998;
            }

            $self->{_links}{'direct_link'} = $link;
        };

        if($@){
            $self->{_links}{'status'} = $@;
        }
    }
    
    return %{ $self->{_links} };
}

1;
