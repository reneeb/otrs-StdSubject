# --
# Kernel/Language/de_StdSubject.pm - the German translation for StdSubject
# Copyright (C) 2016 - 2022 Perl-Services, https://www.perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Language::de_StdSubject;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    my $Lang = $Self->{Translation};

    return if ref $Lang ne 'HASH';

    # Kernel/Config/Files/StdSubject.xml
    $Lang->{'Defines standard subjects for some actions.'} = '';

    return 1;
}

1;
