package CharsetEncoder;

use strict;
use MT::Template;

sub encode {
    my $cb = shift;
    my %args = @_;

    my $ctx = $args{context};
    return if $ctx->stash('isPageBute');

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
    $app->param('process_charset_encoder') ?
         $obj->process_charset_encoder(1) : $obj->process_charset_encoder(0);
    $obj->template_charset_encoding($app->param('template_charset_encoding'));
    1;
}

sub add_script {
    my ($cb, $app, $tmpl) = @_;

    my $plugin = MT->component("CharsetEncoder");
    my $blog_id = $app->blog->id;
    my $enable = $plugin->get_config_value('enable_thisblog', 'blog:'.$blog_id);
    my $separate = $plugin->get_config_value('each_template', 'blog:'.$blog_id);

    return unless ($enable && $separate);

    my $old = <<HERE;
<mt:setvarblock name="html_head" append="1">
HERE
    $old = quotemeta($old);

    my $new = <<HERE;
<mt:setvarblock name="html_head" append="1">
<script type="text/javascript">
function toggleCharset(id) {
    if ("process_charset_encoder_no" == id) {
        toggleDisable('template_charset_encoding', 1);
    } else {
        toggleDisable('template_charset_encoding', 0);
    }
    return false;
}
</script>
</mt:setvarblock>
<mt:setvarblock name="html_head" append="1">
HERE
    $$tmpl =~ s/$old/$new/;
}

sub edit_template_param {
    my ($cb, $app, $param, $tmpl) = @_;

    return unless $param->{id} and ($param->{type} eq 'index' ||
                                    $param->{type} eq 'archive' ||
                                    $param->{type} eq 'page' ||
                                    $param->{type} eq 'individual');

    my $plugin = MT->component("CharsetEncoder");
    my $blog_id = $app->blog->id;
    my $enable = $plugin->get_config_value('enable_thisblog', 'blog:'.$blog_id);
    my $separate = $plugin->get_config_value('each_template', 'blog:'.$blog_id);

    if ($enable && $separate) {
        my $template = MT::Template->load({ id => $app->param('id') });
        my $process = $template->process_charset_encoder();
        my ($process_y, $process_n);
        $process ? $process_y = ' checked="checked"' : $process_n = ' checked="checked"';
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
            label_class => 'top_label',
            required => 0 });

        my $innerHTML = <<TEXT;
    <ul style="margin:10px 0 0 15px">
        <li><input type="radio" name="process_charset_encoder" id="process_charset_encoder_no" value="0" class="" mt:watch-change="1"$process_n onclick="toggleCharset('process_charset_encoder_no');" /> <label for="process_charset_encoder_no"><__trans phrase="No"></label></li>
        <li><input type="radio" name="process_charset_encoder" id="process_charset_encoder_yes" value="1" class="" mt:watch-change="1"$process_y onclick="toggleCharset('process_charset_encoder_yes');" /> <label for="process_charset_encoder_yes"><__trans phrase="Yes"></label>
        <select id="template_charset_encoding" name="template_charset_encoding">
            <option value="utf-8"$encode_utf8 /> UTF-8<__trans phrase="(default)">
            <option value="euc-jp"$encode_eucjp /> EUC-JP
            <option value="shift_jis"$encode_shiftjis /> Shift_JIS
        </select></li>
    </ul>
TEXT
        $newElement->innerHTML($innerHTML);
        my $oldElement = $tmpl->getElementById('linked_file');
        $tmpl->insertBefore($newElement, $oldElement);
    }
}

sub page_bute {
    my $cb = shift;
    my ($output, %args) = @_;

    my $blog = $args{blog};
    my $tmpl = $args{template};

    my $plugin = MT->component("CharsetEncoder");
    my $enable = $plugin->get_config_value('enable_thisblog', 'blog:'.$blog->id);
    if ($enable) {
        my $separate = $plugin->get_config_value('each_template', 'blog:'.$blog->id);

        my $encoding;
        if ($separate) {
            $encoding = $tmpl->template_charset_encoding;
        } else {
            $encoding = $plugin->get_config_value('encoding', 'blog:'.$blog->id);
        }
        if ($args{template}->process_charset_encoder || ($separate == 0)) {
            return if !$encoding; # for 0.02
            return if $encoding eq 'utf-8';

            my $charset = ($encoding eq 'euc-jp') ? 'EUC-JP' : 'Shift_JIS' ;

            $$output = Encode::encode($encoding, $$output);
            $$output =~ s/encoding="\S+"/encoding="$charset"/g;
            $$output =~ s/[^accept-]charset=\S+"/charset=$charset"/g;

            my $ctx = $args{context};
            $ctx->stash('isPageBute', 1);
        }
    }
}

1;
