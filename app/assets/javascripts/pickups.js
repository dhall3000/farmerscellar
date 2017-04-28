$(function()
{

  $('#garageDoorButton').on('click', function () {
    var $btn = $(this).button('loading')
    $.get("http://10.0.0.19:1984/client?command=door2");
    $btn.button('reset')
  })

  $('#agree').on('click', function() {
    $('#pinForm').submit();
  });

  $('#disagree').on('click', function() {
    $('#pinField').val("");
  });

});