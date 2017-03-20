$(document).on('page:load', function () {

  // $('input[type=radio].star').rating();
  $('.start-container').rating();
});

$( document ).on('turbolinks:load', function() {
  $('.start-container').rating();
})


	$(function() {

		var	$window = $(window);
		$window.on('load', function() {
			 $('.start-container').rating();
			 
		});
	});
