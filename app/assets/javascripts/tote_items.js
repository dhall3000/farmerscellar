$(function(){

  function toggleChevron(e) {
    $(e.target).parent().find('span').toggleClass('rotate-180');
  }

  $('#accordion').on('hide.bs.collapse', toggleChevron);
  $('#accordion').on('show.bs.collapse', toggleChevron);

	$('.popover_init').popover();

	$(function () {
	  $('[data-toggle="popover"]').popover()
	})

	$('#frequency_dropdown').change(function() {

		var subscriptionFrequency = $('#frequency_dropdown option:selected').val();
		var nextDeliveryDates = $('#next_delivery_dates').data('dates');
		$('#next_delivery_date').html(nextDeliveryDates[subscriptionFrequency]);
		$('.subscription_frequency').val(subscriptionFrequency);
		
	});

  //for any element that has a collapse class, when it gets collapses, collapse everything else that is collapsible and currently being shown
	$('.collapse').on('show.bs.collapse', function () {
		$('.collapse.in').collapse('hide');
	});

});