$(function()
{
  
  $('#posting_delivery_date').datepicker( { minDate: 1} );
  $('#posting_delivery_date').datepicker( 'option', 'dateFormat', 'DD, MM d, yy' );
  $('#posting_commitment_zone_start').datetimepicker({sideBySide: true, format: "dddd, MMMM Do YYYY, h A"});

});