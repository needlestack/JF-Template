# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl JF-Template.t'

#########################

use strict;
use warnings;

use Test::More tests => 28;
BEGIN { use_ok('JF::Template') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

#-------------------------------------------
# Begin J Field test code
#-------------------------------------------
our ($testname, $t, $got, $expected);

#-------------------------------------------
# we test that warnings are generated propeprly, so we must capture them
#-------------------------------------------
our @expected_warnings;
$SIG{__WARN__} = sub {

    my $warning = shift;

    if (0 and $testname eq "combined") {
        print STDERR "\n\n===\n\t'$warning'\n===\n\n\n";
    }

    # since editing this test script will change the line numbers
    # we look for in the warnings, we normalize those here for our sanity
    $warning =~ s[ at t/JF-Template.t line \d+][ at t/JF-Template.t line 00];

    ok( shift(@expected_warnings) eq $warning, $testname . "-warnings" );
};

# we want to slurp files when we read them
local $/;

#-------------------------------------------
# echo tests
#-------------------------------------------
$testname = "echo";
@expected_warnings = (
    "Invalid args to <% echo %> at line 11 of t/echo.tmpl\n",
    "Invalid args to <% echo %> at line 13 of t/echo.tmpl\n",
);

$t = JF::Template->new();
$t->set_dir("t");

$t->set_value(   test1 => "test1"  );
$t->set_value({  test2 => "test2" });
$t->set_values({ test3 => "test3" });
$t->set_values({
    test4 => "test4",
    test5 => "test5",
    "test.a" => "foo",
    "test.b" => "bar",
});
$got = $t->parse_file("$testname.tmpl");

open FILE, "<t/$testname.result" or die $!;
$expected = <FILE>;
close FILE;

ok( $got eq $expected, $testname );
ok( @expected_warnings == 0, $testname . "-gotallwarnings" );

#-------------------------------------------
# logic tests
#-------------------------------------------
$testname = "logic";
@expected_warnings = (
    "Invalid args to <% if %> ( use '&& || !' instead of 'and or not' ) at line 81 of t/logic.tmpl\n",
    "Invalid args to <% elsif %> ( use '&& || !' instead of 'and or not' ) at line 83 of t/logic.tmpl\n",
    "Invalid args to <% if %> ( use '&& || !' instead of 'and or not' ) at line 87 of t/logic.tmpl\n",
    "Invalid args to <% elsif %> ( use '&& || !' instead of 'and or not' ) at line 89 of t/logic.tmpl\n",
    "Invalid args to <% if %> ( use '&& || !' instead of 'and or not' ) at line 93 of t/logic.tmpl\n",
    "Invalid args to <% elsif %> ( use '&& || !' instead of 'and or not' ) at line 95 of t/logic.tmpl\n",
);

$t = JF::Template->new();
$t->set_dir("t");

$t->set_value(true => 1);
$t->set_value("tr.ue" => 1);

$got = $t->parse_file("$testname.tmpl");

open FILE, "<t/$testname.result" or die $!;
$expected = <FILE>;
close FILE;

ok( $got eq $expected, $testname );
ok( @expected_warnings == 0, $testname . "-gotallwarnings" );

#-------------------------------------------
# loop tests
#-------------------------------------------
$testname = "loops";
@expected_warnings = ();

$t = JF::Template->new();
$t->set_dir("t");

$t->set_value( value => "outer" );

foreach my $i (1..3) {
    my $oloop = $t->get_loop("outerloop");
    $oloop->set_value( value => $i );
    foreach my $j (qw(a b c)) {
        my $iloop = $oloop->get_loop("innerloop");
        $iloop->set_value( value => $j );
    }
}

$got = $t->parse_file("$testname.tmpl");

open FILE, "<t/$testname.result" or die $!;
$expected = <FILE>;
close FILE;

ok( $got eq $expected, $testname );
ok( @expected_warnings == 0, $testname . "-gotallwarnings" );

#-------------------------------------------
# include tests
#-------------------------------------------
$testname = "include";
@expected_warnings = (
    "Recursive <% include %>: t/include.tmpl at line 42 of t/include.tmpl\n",
    "Recursive <% include %>: t/include.tmpl at line 3 of t/include3.tmpl\n",
);

$t = JF::Template->new();
$t->set_dir("t");

$t->set_value( foo => "include2" );

# test that loops maintain the directory
foreach my $i (1,2) {
    my $loop = $t->get_loop("loop_include");
    $loop->set_value( num => $i );
}

$got = $t->parse_file("$testname.tmpl");

open FILE, "<t/$testname.result" or die $!;
$expected = <FILE>;
close FILE;

ok( $got eq $expected, $testname );
ok( @expected_warnings == 0, $testname . "-gotallwarnings" );

#-------------------------------------------
# combined tests
#-------------------------------------------
$testname = "combined";
@expected_warnings = (
    "Blank hash key to set_value() ignored at t/JF-Template.t line 00.\n",
    "Blank hash key to set_value() ignored at t/JF-Template.t line 00.\n",
    "Use of uninitialized value in anonymous hash ({}) at t/JF-Template.t line 00.\n",
    "Blank hashref key to set_value({}) ignored at t/JF-Template.t line 00.\n",
    "Invalid args to <% set %> at line 24 of t/combined.tmpl\n",
    "Invalid args to <% set %> at line 25 of t/combined.tmpl\n",
    "Invalid args to <% set %> at line 26 of t/combined.tmpl\n",
);

$t = JF::Template->new();
$t->set_dir("t");

$t->set_value( value => "outer" );

$t->set_value( undef() => "1" );
$t->set_value( "" => "1" );

# truly, the undef() doesn't even make it to set_value()
# because in an anonymous hash perl complains about undefined
# keys right here and converts it to... a blank?
$t->set_value({ undef() => "1", "", => "1"});

foreach my $i (1..4) {
    my $oloop = $t->get_loop("outerloop");
    $oloop->set_value( value => $i );
    if ($i % 2 == 0) {
        $oloop->set_value( do_set => 1 );
    }
    foreach my $j (qw(a b c d)) {
        my $iloop = $oloop->get_loop("innerloop");
        $iloop->set_value( value => $j );
    }
}

$got = $t->parse_file("$testname.tmpl");

open FILE, "<t/$testname.result" or die $!;
$expected = <FILE>;
close FILE;

ok( $got eq $expected, $testname );
ok( @expected_warnings == 0, $testname . "-gotallwarnings" );



