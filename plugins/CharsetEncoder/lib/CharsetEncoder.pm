package CharsetEncoder;

use strict;

sub encode {
    my $cb = shift;
    my %args = @_;
    my $html = $args{content};
    my $blog = $args{blog};

    my $plugin = MT->component("CharsetEncoder");
    my $encoding = $plugin->get_config_value('encoding', 'blog:'.$blog->id);
    return if !$encoding; # for 0.02
    return if $encoding eq 'utf-8';

    my $charset = ($encoding eq 'euc-jp') ? 'EUC-JP' : 'Shift_JIS' ;

    $$html = Encode::encode($encoding, $$html);
    $$html =~ s/encoding="\S+"/encoding="$charset"/g;
    $$html =~ s/[^accept-]charset=\S+"/charset=$charset"/g;
}

1;
