$(function(){

  $('#beta_users_explanation').popover();

  $("#user_account_type_0").change(function()
  {
    if ($(this).is(':checked'))
    {
      console.log("customer account sign up checked");
      $("#producer_input").attr("hidden", true);
    }
  });

  $("#user_account_type_1").change(function()
  {
    if ($(this).is(':checked'))
    {
      console.log("producer account sign up checked");
      $("#producer_input").removeAttr("hidden");
    }
  });
});