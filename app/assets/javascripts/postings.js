$(function()
{ 

  $('#this-week').change(function(){

    if ($('.next-week').is(':visible')) {      
      $('.next-week').fadeOut('fast', function() {
        $('.this-week').fadeIn('fast', function() {
        });
      });
    }

    if ($('.future').is(':visible')) {
      $('.future').fadeOut('fast', function() {
        $('.this-week').fadeIn('fast', function() {
        });
      });
    }    

  });

  $('#next-week').change(function(){

    if ($('.this-week').is(':visible')) {
      $('.this-week').fadeOut('fast', function() {
        $('.next-week').fadeIn('fast', function() {
        });
      });
    }


    if ($('.future').is(':visible')) {
      $('.future').fadeOut('fast', function() {
        $('.next-week').fadeIn('fast', function() {
        });
      });
    }

  });

  $('#future').change(function(){

    if ($('.this-week').is(':visible')) {
      $('.this-week').fadeOut('fast', function() {
        $('.future').fadeIn('fast', function() {
        });
      });
    }

    if ($('.next-week').is(':visible')) {
      $('.next-week').fadeOut('fast', function() {
        $('.future').fadeIn('fast', function() {
        });
      });
    }

  });

  $('#dtpDeliveryDate').datetimepicker({
    daysOfWeekDisabled: [1],
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