# --
# Copyright (C) 2016 Perl-Services.de, http://www.perl-services.de/
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

    if ( $HasTags ) {
        my %Ticket = $TicketObject->TicketGet(
            TicketID => $TicketID,
        );

        $Translated =~ s{
            <
                (TicketNumber|Title)
            >
        }{$Ticket{$1}}xmsg;
    } 

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

1;
