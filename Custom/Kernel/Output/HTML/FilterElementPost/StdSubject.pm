# --
# Copyright (C) 2016 - 2022 Perl-Services.de, https://www.perl-services.de/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::FilterElementPost::StdSubject;

use strict;
use warnings;

use List::Util qw(first);

our @ObjectDependencies = qw(
    Kernel::Config
    Kernel::System::Log
    Kernel::System::Main
    Kernel::System::DB
    Kernel::System::Web::Request
    Kernel::Output::HTML::Layout
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    $Self->{UserID} = $Param{UserID};

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    # get template name
    my $Templatename = $Param{TemplateFile} || '';
    return 1 if !$Templatename;
    return 1 if !$Param{Templates}->{$Templatename};

    my $ConfigObject   = $Kernel::OM->Get('Kernel::Config');
    my $ParamObject    = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $LanguageObject = $Kernel::OM->Get('Kernel::Language');
    my $LayoutObject   = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $TicketObject   = $Kernel::OM->Get('Kernel::System::Ticket');

    my $Action   = $ParamObject->GetParam( Param => 'Action' ) || '';
    my $Subjects = $ConfigObject->Get('StdSubject::Subjects') || {};
    my $Subject  = $Subjects->{$Templatename} || $Subjects->{$Action} || $Subjects->{'*'} || '';

    return 1 if !$Subject;

    my $TicketID = $ParamObject->GetParam( Param => 'TicketID' );
    return 1 if !$TicketID;

    my $Translated = $LanguageObject->Translate( $Subject );

    my $HasTags = $Translated =~ m{
        <
            (?:TicketNumber|Title)
        >
    }xms;

    my %Ticket = $TicketObject->TicketGet(
        TicketID      => $TicketID,
	DynamicFields => 1,
    );

    if ( $HasTags ) {
        $Translated =~ s{
            <
                (TicketNumber|Title)
            >
        }{$Ticket{$1}}xmsg;
    } 

    $Translated = $Self->_ReplaceMacros(
        Text           => $Translated,
        UserID         => $Self->{UserID} || $LayoutObject->{UserID},
        Ticket         => \%Ticket,
	LanguageObject => $LanguageObject,
    );

    my $SubjectContent = $LayoutObject->Output(
        Template => '[% Data.Subject | html %]',
        Data     => { Subject => $Translated },
    );

    $LayoutObject->AddJSOnDocumentComplete(
        Code => qq~
            \$('#Subject').val("$SubjectContent");
         ~,
    );

    return 1;
}

sub _ReplaceMacros {
    my ( $Self, %Param ) = @_;

    my $LogObject       = $Kernel::OM->Get('Kernel::System::Log');
    my $ConfigObject    = $Kernel::OM->Get('Kernel::Config');
    my $UserObject      = $Kernel::OM->Get('Kernel::System::User');
    my $HTMLUtilsObject = $Kernel::OM->Get('Kernel::System::HTMLUtils');

    # check needed stuff
    for my $Needed (qw(Text UserID Ticket LanguageObject)) {
        if ( !defined $Param{$Needed} ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    my $Text = $Param{Text};

    # determine what "macro" delimiters are used
    my $Start = '<';
    my $End   = '>';
    my $NL    = "\n";

    my $LanguageObject = $Param{LanguageObject};

    my %TicketData = %{ $Param{Ticket} };
    for my $Field (qw(State Priority)) {
        $TicketData{$Field} = $LanguageObject->Translate( $TicketData{$Field} );
    }

    for my $DFKey ( grep{ $_ =~ m{\ADynamicField} }keys %TicketData ) {
        $TicketData{$DFKey} = $LanguageObject->Translate( $TicketData{$DFKey} );
    }

    # replace config options
    my $Tag = $Start . 'OTRS_CONFIG_';
    $Text =~ s{ $Tag (.+?) $End }{$ConfigObject->Get($1)}egx;

    # cleanup
    $Text =~ s{ $Tag .+? $End }{-}gi;

    $Tag = $Start . 'OTRS_Agent_';
    my $Tag2 = $Start . 'OTRS_CURRENT_';
    my %CurrentUser = $UserObject->GetUserData( UserID => $Param{UserID} );

    # html quoting of content
    if ( $Param{RichText} ) {
        KEY:
        for my $Key ( sort keys %CurrentUser ) {
            next KEY if !$CurrentUser{$Key};
            $CurrentUser{$Key} = $HTMLUtilsObject->ToHTML(
                String => $CurrentUser{$Key},
            );
        }
    }

    # replace it
    KEY:
    for my $Key ( sort keys %CurrentUser ) {
        next KEY if !defined $CurrentUser{$Key};
        $Text =~ s{ $Tag $Key $End }{$CurrentUser{$Key}}gxmsi;
        $Text =~ s{ $Tag2 $Key $End }{$CurrentUser{$Key}}gxmsi;
    }

    # replace other needed stuff
    $Text =~ s{ $Start OTRS_FIRST_NAME $End }{$CurrentUser{UserFirstname}}gxms;
    $Text =~ s{ $Start OTRS_LAST_NAME $End }{$CurrentUser{UserLastname}}gxms;

    # cleanup
    $Text =~ s{ $Tag .+? $End}{-}xmsgi;
    $Text =~ s{ $Tag2 .+? $End}{-}xmsgi;

    # replace <OTRS_TICKET_... tags
    {
        my $Tag = $Start . 'OTRS_TICKET_';

        # html quoting of content
        if ( $Param{RichText} ) {
            KEY:
            for my $Key ( sort keys %TicketData ) {
                next KEY if !$TicketData{$Key};
                $TicketData{$Key} = $HTMLUtilsObject->ToHTML(
                    String => $TicketData{$Key},
                );
            }
        }

        # replace it
        KEY:
        for my $Key ( sort keys %TicketData ) {
            next KEY if !defined $TicketData{$Key};
            $Text =~ s{ $Tag $Key $End }{$TicketData{$Key}}gxmsi;
        }

        # cleanup
        $Text =~ s{ $Tag .+? $End}{-}gxmsi;
    }

    return $Text;
}


1;
