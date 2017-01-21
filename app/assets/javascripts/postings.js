$(function()
{ 

  function toggleImportantNotesTruncation(e) {    
    $('#importantNotes').toggleClass('truncated-text-line');
  }

  $('#importantNotesBody').on('show.bs.collapse', toggleImportantNotesTruncation);
  $('#importantNotesBody').on('hide.bs.collapse', toggleImportantNotesTruncation);

  function toggleProducerNameTruncation(e) {    
    $('#producerName').toggleClass('truncated-text-line');
  }

  $('#producerDetails').on('show.bs.collapse', toggleProducerNameTruncation);
  $('#producerDetails').on('hide.bs.collapse', toggleProducerNameTruncation);

  function toggleDescriptionTruncation(e) {    
    $('#productDescription').toggleClass('truncated-text-line');
  }

  $('#descriptionBody').on('show.bs.collapse', toggleDescriptionTruncation);
  $('#descriptionBody').on('hide.bs.collapse', toggleDescriptionTruncation);

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