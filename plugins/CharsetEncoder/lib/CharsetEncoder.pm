package CharsetEncoder;

use strict;

sub encode {
    my $cb = shift;
    my %args = @_;
    my $html = $args{content};
    my $blog = $args{blog};

    my $plugin = MT->component("CharsetEncoder");
    my $enable = $plugin->get_config_value('enable_thisblog', 'blog:'.$blog->id);
    if ($enable) {
        my $separate = $plugin->get_config_value('each_template', 'blog:'.$blog->id);
        my $tmpl = $args{template};
        my $encoding;
        if ($separate) {
            $encoding = $tmpl->template_charset_encoding;
        } else {
            $encoding = $plugin->get_config_value('encoding', 'blog:'.$blog->id);
        }
        if ($tmpl->process_charset_encoder || ($separate == 0)) {
            return if !$encoding; # for 0.02
            return if $encoding eq 'utf-8';

            my $charset = ($encoding eq 'euc-jp') ? 'EUC-JP' : 'Shift_JIS' ;

            $$html = Encode::encode($encoding, $$html);
            $$html =~ s/encoding="\S+"/encoding="$charset"/g;
            $$html =~ s/[^accept-]charset=\S+"/charset=$charset"/g;
        }
    }
}

sub cms_pre_save_template {
	my ($cb, $app, $obj) = @_;
	if ($app->param('process_charset_encoder')) {
		$obj->process_charset_encoder(1);
	} else {
		$obj->process_charset_encoder(0);
	}
	my $encode = $app->param('template_charset_encoding');
	$obj->template_charset_encoding($encode);
	1;
}

sub edit_template_param {
	my ($cb, $app, $param, $tmpl) = @_;
	unless ($param->{id} and $param->{type} eq 'index') { return; }
    my $plugin = MT->component("CharsetEncoder");
    my $blogid = $app->blog->id;
    my $enable = $plugin->get_config_value('enable_thisblog', 'blog:'.$blogid);
    my $separate = $plugin->get_config_value('each_template', 'blog:'.$blogid);
    if ($enable && $separate) {

	use MT::Template;
	my $template = MT::Template->load({ id => $app->param('id') });

	my $process = $template->process_charset_encoder();
	my ($process_y, $process_n);
	if ($process) {
		$process_y = ' checked="checked"';
	} else {
		$process_n = ' checked="checked"';
	}
	my $encode = $template->template_charset_encoding();
	my ($encode_eucjp, $encode_shiftjis, $encode_utf8);
	if ($encode eq 'euc-jp') {
		$encode_eucjp = ' selected="selected"';
	} elsif ($encode eq 'shift_jis') {
		$encode_shiftjis = ' selected="selected"';
	} else {
		$encode_utf8 = ' selected="selected"';
	}
	my $newElement = $tmpl->createElement('app:setting', {
		id => 'process_charset_encoder',
		label => $plugin->translate('Process Encode Charset') ,
		required => 0 });
	my $innerHTML = <<TEXT;
        <input type="radio" name="process_charset_encoder" id="process_charset_encoder_yes" value="1" class="" mt:watch-change="1"$process_y />&nbsp;<__trans phrase="Yes">&nbsp;/&nbsp;
        <input type="radio" name="process_charset_encoder" id="process_charset_encoder_no" value="0" class="" mt:watch-change="1"$process_n />&nbsp;<__trans phrase="No">&nbsp;
        <select name="template_charset_encoding">
            <option value="utf-8"$encode_utf8 /> UTF-8<__trans phrase="(default)">
            <option value="euc-jp"$encode_eucjp /> EUC-JP
            <option value="shift_jis"$encode_shiftjis /> Shift_JIS
        </select>
TEXT
	$newElement->innerHTML($innerHTML);
	my $oldElement = $tmpl->getElementById('identifier');
	$tmpl->insertAfter($newElement, $oldElement);
	
	}
}

1;
