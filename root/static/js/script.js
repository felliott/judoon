/* Author: Fitz Elliott

*/

// "use strict";


/* ========================================

   Link Builder Modal functions

   ======================================== */


// open and initialize the link modal
function pbuild_open_link_form(link_widget_button) {
    var this_btn = link_widget_button;
    var widget   = $(this_btn).parent();
    $('#linkModal').data('widget_id', widget.attr('id'));

    var props = {
        url:   judoon.linkbuilder.get_attrs(widget, 'url'),
        label: judoon.linkbuilder.get_attrs(widget, 'label')
    };

    // initialize url form values
    var default_label = 'Link';
    var url_radio = judoon.linkbuilder.url.get_type();
    if (props.url.type === 'accession') {
        url_radio.val(['accession']);
        judoon.linkbuilder.url.accession.set_source(props.url['variable-segment-1']);
        judoon.linkbuilder.url.accession.set_site(props.url.accession);
        default_label = sitelinker_sites[props.url.accession].label;
    }
    else if (props.url.type === 'variable') {
        var not_empty = /\S/;
        if (not_empty.test(props.url['text-segment-1'])) {
            url_radio.val(['variable_complex']);
            $('#constructed_url_source').val(props.url['variable-segment-1']);
            $('#constructed_url_prefix').val(props.url['text-segment-1']);
            $('#constructed_url_suffix').val(props.url['text-segment-2']);
        }
        else {
            url_radio.val(['variable_simple']);
            $('#link_url_source').val(props.url['variable-segment-1']);
        }
    }
    else if (props.url.type === 'static') {
        url_radio.val(['static']);
        $('#link_widget_url_static').val(props.url['text-segment-1']);
    }
    else {
        // do what?
        // do nothing.
    }

    // initialize label form values
    var label_radio = judoon.linkbuilder.label.get_type();
    if (props.label.type === "accession") {
        label_radio.val(['url']);
    }
    else if (props.label.type === "variable") {
        label_radio.val(['variable']);
        judoon.linkbuilder.label.dynamic.get_source().val(props.label['variable-segment-1']);
        $('#label_source_prefix').val(props.label['text-segment-1']);
        $('#label_source_suffix').val(props.label['text-segment-2']);
    }
    else if (props.label.type === "static") {
        if (props.label['text-segment-1'] === default_label) {
            label_radio.val(['default']);
        }
        else {
            label_radio.val(['static']);
            $('#link_label_static').val(props.label['text-segment-1']);
        }
    }
    else {
        // do what?
        // do nothing.
    }

    judoon.linkbuilder.preview.update();

    // show the modal
    $('#linkModal').modal();
}

// Runs when user clicks 'submit' on the link modal.
// Responsible for reading the modal forms and writing
// out the appropriate html into the canvas
function pbuild_submit_link_form() {
    $('#linkModal').modal('hide');
    var widget_id = $('#linkModal').data('widget_id');
    var widget    = $('#'+widget_id);

    // set link url properties
    var url_attrs = {};
    var url_type  = judoon.linkbuilder.url.get_type().filter(':checked').val();
    if (url_type === 'static') {
        url_attrs.type = 'static';
        url_attrs['text-segment-1'] = $('#link_widget_url_static').val();
    }
    else if (url_type === 'variable_simple') {
        url_attrs.type = 'variable';
        url_attrs['text-segment-1']     = url_prefixes[$('#link_url_source').val()];
        url_attrs['variable-segment-1'] = $('#link_url_source').val();
    }
    else if (url_type === 'variable_complex') {
        url_attrs.type = 'variable';
        url_attrs['variable-segment-1'] = $('#constructed_url_source').val();
        url_attrs['text-segment-1']     = $('#constructed_url_prefix').val();
        url_attrs['text-segment-2']     = $('#constructed_url_suffix').val();
    }
    else if (url_type === 'accession') {
        var link_source_val = judoon.linkbuilder.url.accession.get_source().val();
        var link_site_val   = judoon.linkbuilder.url.accession.get_site().val();
        var acc_type        = column_acctype[link_source_val];
        url_attrs.type                  = 'accession';
        url_attrs.accession             = link_site_val;
        url_attrs['text-segment-1']     = pbuild_links[link_site_val][acc_type].prefix;
        url_attrs['text-segment-2']     = pbuild_links[link_site_val][acc_type].postfix;
        url_attrs['variable-segment-1'] = link_source_val;
    }
    else {
        throw {
            name : 'InvalidFieldError',
            message : url_type + ' is not a supported url_type'
        };
    }
    judoon.linkbuilder.set_attrs(widget, 'url', url_attrs);


    // set label properties
    var label_type = judoon.linkbuilder.label.get_type().filter(':checked').val();
    var label_attrs = {};
    if (label_type === 'default') {
        if (url_attrs.type === 'static' || url_attrs.type === 'variable') {
            label_attrs.type = 'static';
            label_attrs['text-segment-1'] = 'Link';
        }
        else {
            label_attrs.type = 'static';
            label_attrs['text-segment-1'] = sitelinker_sites[url_attrs.accession].label;
        }
    }
    else if (label_type === 'url') {
        label_attrs = url_attrs;
    }
    else if (label_type === 'static') {
        label_attrs['text-segment-1'] = $('#link_label_static').val();
        label_attrs.type = 'static';
    }
    else if (label_type === 'variable') {
        label_attrs['text-segment-1']     = $('#label_source_prefix').val();
        label_attrs['variable-segment-1'] = $('#label_source').val();
        label_attrs['text-segment-2']     = $('#label_source_suffix').val();
        label_attrs.type = 'variable';
    }
    else {
        throw {
            name : 'InvalidFieldError',
            message : label_type + ' is not a supported label type'
        };
    }
    judoon.linkbuilder.set_attrs(widget, 'label', label_attrs);
    

    // Update canvas display
    var display_label = $('#link_widget_label_preview').text();
    var display_url   = $('#link_widget_url_preview').text();
    var link_display  = "Link to: ";
    if (display_label === display_url) {
        link_display += display_url;
    }
    else {
        link_display += display_label + ' (' + display_url + ')';
    }
    widget.find('.btn-edit-link').first().attr('placeholder',link_display);
}
