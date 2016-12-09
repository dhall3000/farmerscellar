$(function()
{

  setInterval(spinContinuously, 720);
  function spinContinuously() {
    $('.spin-continuously').toggleClass('rotate-360');
  }

  //this was originally added for the Add to Tote page, currently at app/views/tote_items/new.html.erb
  //so you can search there for the accordion element for reference if ever a change is needed
  function toggleChevron(e) {
    $(e.target).parent().find('span').toggleClass('rotate-180');
  }
  $('#accordion').on('hide.bs.collapse', toggleChevron);
  $('#accordion').on('show.bs.collapse', toggleChevron);

  $('#access_code_explanation').popover();
  $('.popover_init').popover();

  window.fbAsyncInit = function() {
    FB.init({
      appId      : '597003080458571',
      xfbml      : true,
      version    : 'v2.6'
    });
  };

  (function(d, s, id){
     var js, fjs = d.getElementsByTagName(s)[0];
     if (d.getElementById(id)) {return;}
     js = d.createElement(s); js.id = id;
     js.src = "//connect.facebook.net/en_US/sdk.js";
     fjs.parentNode.insertBefore(js, fjs);
   }(document, 'script', 'facebook-jssdk'));
   
});