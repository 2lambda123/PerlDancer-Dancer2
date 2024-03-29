use strict;
use warnings;

use Test::More;
use Plack::Test;
use HTTP::Request::Common;
use Ref::Util qw<is_coderef>;

{
    package CustomError;

    use Dancer2;

    set views      => 't/corpus/pretty';
    set public_dir => 't/corpus/pretty_public';

    get '/error' => sub {
        send_error "oh my", 505;
    };

    get '/public' => sub {
        send_error "static", 510;
    };
}

{
    package StandardError;

    use Dancer2;
    set show_stacktrace => 1;

    get '/no_template' => sub {
        send_error "oopsie", 404;
    };
}

my $custom_error_app   = CustomError->to_app;
my $standard_error_app = StandardError->to_app;

ok( is_coderef($custom_error_app), 'Got app' );
ok( is_coderef($standard_error_app), 'Got app' );

my $custom_error_test   = Plack::Test->create($custom_error_app);
my $standard_error_test = Plack::Test->create($standard_error_app);

subtest "/error" => sub {
    my $res = $custom_error_test->request( GET '/error' );

    is $res->code, 505, 'send_error sets the status to 505';
    like $res->content, qr{Template selected}, 'Error message looks good';
    like $res->content, qr{message: oh my};
    like $res->content, qr{status: 505};
};

subtest "/public" => sub {
    my $res = $custom_error_test->request( GET '/public' );

    is $res->code, 510, 'send_error sets the status to 510';
    like $res->content, qr{Static page}, 'Error message looks good';
};

subtest '404 with static template' => sub {
    my $res = $custom_error_test->request( GET '/middle/of/nowhere' );

    is $res->code, 404, 'unknown route => 404';
    like $res->content, qr{you're lost}i, 'Error message looks good';
};

subtest "/no_template" => sub {
    my $res = $standard_error_test->request( GET '/no_template' );

    is $res->code, 404, 'send_error sets the status to 404';
    like $res->content, qr{<h1>Error 404 - Not Found</h1>},
      'Error message looks good';
    unlike $res->content, qr{Stack}, 'Error contains no stack trace';
};

done_testing;
