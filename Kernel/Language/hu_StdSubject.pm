# --
# Kernel/Language/hu_StdSubject.pm - the Hungarian translation for StdSubject
# Copyright (C) 2016 Perl-Services, http://www.perl-services.de
# Copyright (C) 2016 Balázs Úr, http://www.otrs-megoldasok.hu
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Language::hu_StdSubject;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    my $Lang = $Self->{Translation};

    return if ref $Lang ne 'HASH';

    # Kernel/Config/Files/StdSubject.xml
    $Lang->{'Defines standard subjects for some actions.'} = 'Szabványos tárgyakat határoz meg néhány műveletnél.';

    return 1;
}

1;
