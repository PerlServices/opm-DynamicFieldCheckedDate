# --
# Copyright (C) 2017 Perl-Services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::DynamicField::Driver::CheckedDate;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

use Kernel::Language qw(Translatable);

use base qw(Kernel::System::DynamicField::Driver::Date);

sub EditFieldValueGet {
    my ( $Self, %Param ) = @_;

    # set the Prefix as the dynamic field name
    my $Prefix = 'DynamicField_' . $Param{DynamicFieldConfig}->{Name};

    my %DynamicFieldValues;

    # check if there is a Template and retrieve the dynamic field value from there
    if ( IsHashRefWithData( $Param{Template} ) && defined $Param{Template}->{ $Prefix . 'Used' } ) {
        for my $Type (qw(Used Year Month Day)) {
            $DynamicFieldValues{ $Prefix . $Type } = $Param{Template}->{ $Prefix . $Type } || 0;
        }
    }

    # otherwise get dynamic field value from the web request
    elsif (
        defined $Param{ParamObject}
        && ref $Param{ParamObject} eq 'Kernel::System::Web::Request'
        )
    {
        for my $Type (qw(Used Year Month Day)) {
            $DynamicFieldValues{ $Prefix . $Type } = $Param{ParamObject}->GetParam(
                Param => $Prefix . $Type,
            ) || 0;
        }
    }

    # complete the rest of the date with 0s to have a valid Date/Time value
    for my $Type (qw(Hour Minute)) {
        $DynamicFieldValues{ $Prefix . $Type } = 0;
    }

# ---
# PS
# ---
    # pre-check the field when
    #   - only an action is given
    #   - no action at all
    my $PreCheck = 0;

    if ( !$DynamicFieldValues{ $Prefix . 'Used' }
        && !$DynamicFieldValues{ $Prefix . 'Year' }
        && !$DynamicFieldValues{ $Prefix . 'Month' }
        && !$DynamicFieldValues{ $Prefix . 'Day' }
        )
    {
        $PreCheck = 1;
    }

    if ( $PreCheck && !$DynamicFieldValues{ $Prefix . 'Year' } ) {
        my $TimeObject = $Kernel::OM->Get('Kernel::System::Time');
        my $Config     = $Param{DynamicFieldConfig};
        my $DiffTime   = $Config->{DefaultValue};

        $DynamicFieldValues{$Prefix . 'Used'} = 1;

        my ($Sec, $Min, $Hour, $Day, $Month, $Year, $WeekDay) = $TimeObject->SystemTime2Date(
            SystemTime => $TimeObject->SystemTime() + $DiffTime,
        );

        $DynamicFieldValues{ $Prefix . 'Day' }   ||= $Day;
        $DynamicFieldValues{ $Prefix . 'Month' } ||= $Month;
        $DynamicFieldValues{ $Prefix . 'Year' }  ||= $Year;
    }
# ---

    # return if the field is empty (e.g. initial screen)
    return if !$DynamicFieldValues{ $Prefix . 'Used' }
        && !$DynamicFieldValues{ $Prefix . 'Year' }
        && !$DynamicFieldValues{ $Prefix . 'Month' }
        && !$DynamicFieldValues{ $Prefix . 'Day' };

    # check if return value structure is needed
    if ( defined $Param{ReturnValueStructure} && $Param{ReturnValueStructure} eq '1' ) {
        return \%DynamicFieldValues;
    }

    # check if return template structure is needed
    if ( defined $Param{ReturnTemplateStructure} && $Param{ReturnTemplateStructure} eq '1' ) {
        return \%DynamicFieldValues;
    }

    # add seconds, as 0 to the DynamicFieldValues hash
    $DynamicFieldValues{ 'DynamicField_' . $Param{DynamicFieldConfig}->{Name} . 'Second' } = 0;

    my $ManualTimeStamp = '';

    if ( $DynamicFieldValues{ $Prefix . 'Used' } ) {

        # add a leading zero for date parts that could be less than ten to generate a correct
        # time stamp
        for my $Type (qw(Month Day Hour Minute Second)) {
            $DynamicFieldValues{ $Prefix . $Type } = sprintf "%02d",
# ---
# PS
# ---
#                $DynamicFieldValues{ $Prefix . $Type };
                $DynamicFieldValues{ $Prefix . $Type } || 0;
# ---
        }
        my $Year  = $DynamicFieldValues{ $Prefix . 'Year' }  || '0000';
        my $Month = $DynamicFieldValues{ $Prefix . 'Month' } || '00';
        my $Day   = $DynamicFieldValues{ $Prefix . 'Day' }   || '00';
        my $Hour  = '00';
        my $Minute = '00';
        my $Second = '00';

        $ManualTimeStamp =
            $Year . '-' . $Month . '-' . $Day . ' '
            . $Hour . ':' . $Minute . ':' . $Second;
    }

    return $ManualTimeStamp;
}

1;

=back

=head1 TERMS AND CONDITIONS

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
