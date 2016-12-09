$(function()
{

  setInterval(spinContinuously, 720);
  function spinContinuously() {
    $('.spin-continuously').toggleClass('rotate-360');
  }

  $('.collapse').on('show.bs.collapse', toggleChevron);
  $('.collapse').on('hide.bs.collapse', toggleChevron);
  function toggleChevron(e) {        
    $(e.target).parent().find('span.glyphicon-chevron-up').toggleClass('rotate-180');
  }  

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