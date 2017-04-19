$(function()
{ 

  if (sessionStorage['weekSelection'] == "next") {
    $('#next-week').click();
    $('.this-week').hide();
    $('.next-week').show();
    $('.future').hide();    
  }

  if (sessionStorage['weekSelection'] == "future") {
    $('#future').click();
    $('.this-week').hide();
    $('.next-week').hide();
    $('.future').show();    
  }

  $('#this-week').change(function(){

    if ($('.next-week').is(':visible')) {      
      $('.next-week').fadeOut('fast', function() {
        $('.this-week').fadeIn('fast', function() {
        });
      });
      sessionStorage['weekSelection'] = "this";
    }

    if ($('.future').is(':visible')) {
      $('.future').fadeOut('fast', function() {
        $('.this-week').fadeIn('fast', function() {
        });
      });
      sessionStorage['weekSelection'] = "this";
    }    

  });

  $('#next-week').change(function(){

    if ($('.this-week').is(':visible')) {
      $('.this-week').fadeOut('fast', function() {
        $('.next-week').fadeIn('fast', function() {
        });
      });
      sessionStorage['weekSelection'] = "next";
    }


    if ($('.future').is(':visible')) {
      $('.future').fadeOut('fast', function() {
        $('.next-week').fadeIn('fast', function() {
        });
      });
      sessionStorage['weekSelection'] = "next";
    }

  });

  $('#future').change(function(){

    if ($('.this-week').is(':visible')) {
      $('.this-week').fadeOut('fast', function() {
        $('.future').fadeIn('fast', function() {
        });
      });
      sessionStorage['weekSelection'] = "future";
    }

    if ($('.next-week').is(':visible')) {
      $('.next-week').fadeOut('fast', function() {
        $('.future').fadeIn('fast', function() {
        });
      });
      sessionStorage['weekSelection'] = "future";
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