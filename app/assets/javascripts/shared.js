$(function()
{

  //this is here for iOS. divs don't listen to click events so can't toggle collapse without this code.
  //see here: http://stackoverflow.com/questions/33074160/bootstrap-collapse-half-working-on-iphone  
  $('div[data-toggle="collapse"], span[data-toggle="collapse"]').on('click', function() {});

  //////////////////////////////////////////////////////////////////////////
  //https://github.com/twbs/bootstrap/issues/16360
  //If you are using the javascript api you can simply initialize the elements as an accordion first with the following code:
  $('#accordion .panel-collapse').collapse({ 
    parent: '#accordion', 
    toggle: false 
  });
  /*
  This will let all the targets know that they have a parent to worry about. Now when you run the code:
    $('#collapseTwo').collapse('show')
  You get the expected behavior.
  The problem is that if you're relying on just the data api, the api lazy instantiates, something which .collapse('show') doesn't take into account.
  */
  //////////////////////////////////////////////////////////////////////////

  //on collapse shown event, jump to anchor if exist
  $('.collapse').on('shown.bs.collapse', function() {
    if (location.hash) {      
      location.href = location.hash;
    }
  });

  $('.self-link').on('click', function() {    
    expandCollapseWithHash(this.hash);
  });  

  $('.collapse').on('show.bs.collapse', rotateGlyph180);
  $('.collapse').on('hide.bs.collapse', rotateGlyph180);

  function expandCollapseWithHash(hash) {

    var $collapse = $(hash).parents('.collapse').first();

    if ($collapse.length == 0) {
      $collapse = $(hash).siblings('.collapse').first();
    }

    if ($collapse.length == 0) {
      return;
    }

    $collapse.collapse('show');

  }

  handleAnchorLinksFromOtherPages();
  function handleAnchorLinksFromOtherPages() {

    //if we've come from another page and there's a hash...
    if (location.hash) {
      expandCollapseWithHash(location.hash);
    }

  }

  function rotateGlyph180(e) {    
    rotateGlyphTarget180($(e.target));
  }

  function rotateGlyphTarget180(collapseElement) {    
    $(collapseElement.data('chevron')).toggleClass('rotate-180');
  }
  
  $('#access_code_explanation').popover();
  $('.popover_init').popover();
  
  setInterval(spinContinuously, 720);
  function spinContinuously() {
    $('.spin-continuously').toggleClass('rotate-360');
  }

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