$(function()
{ 

  $('#dtpDeliveryDate').datetimepicker({
    daysOfWeekDisabled: [0],
    format: "dddd, MMMM Do YYYY",
    ignoreReadonly: true
  }); 
  
  $('#dtpOrderCutoff').datetimepicker({
    stepping: 5,
    format: "dddd, MMMM Do YYYY, h:mm A",
    ignoreReadonly: true
  });

  if ($('#dtpDeliveryDate').length) {
    var momentDate = moment($('#dtpDeliveryDate').data('deliverydate'), 'YYYY-MM-DD HH:mm');
    $('#dtpDeliveryDate').data("DateTimePicker").date(momentDate);
  }

  if ($('#dtpOrderCutoff').length) {
    var momentDate = moment($('#dtpOrderCutoff').data('ordercutoff'), 'YYYY-MM-DD HH:mm');
    $('#dtpOrderCutoff').data("DateTimePicker").date(momentDate);
  }

  $(function(){ $('.btn').popover(); });

});