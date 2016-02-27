$(function()
{
  $('.btn').popover();  
  $('#posting_delivery_date').datepicker( { minDate: 1} );
  $('#posting_delivery_date').datepicker( 'option', 'dateFormat', 'DD, MM d, yy' );
});