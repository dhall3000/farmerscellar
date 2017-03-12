$(function()
{

  $('#agree').on('click', function() {
    $('#pinForm').submit();
  });

  $('#disagree').on('click', function() {
    $('#pinField').val("");
  });

});