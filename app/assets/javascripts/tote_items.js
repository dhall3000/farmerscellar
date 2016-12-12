$(function(){

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

});