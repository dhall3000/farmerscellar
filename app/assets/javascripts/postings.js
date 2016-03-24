$(function()
{ 
  $('#dtpDeliveryDate').datetimepicker({daysOfWeekDisabled: [0], format: "dddd, MMMM Do YYYY", ignoreReadonly: true}); 
  $('#dtpCommitmentZoneStart').datetimepicker({stepping: 5, format: "dddd, MMMM Do YYYY, h:mm A", ignoreReadonly: true});
  $(function(){ $('.btn').popover(); });
});