var toggleNowPlaying = $('.toggle-now-playing'),
		nowPlaying = $('.now-playing');

$(window).on("resize", function() {
  $(".main").css({
    height: ($(window).height()) + "px"
  });
}).resize();


toggleNowPlaying.on('click', function() {
  $(this).toggleClass('flip-icon');
  nowPlaying.toggleClass('hidden');
  if (nowPlaying.hasClass('hidden')) {
  	nowPlaying.css({
	  	marginBottom: -(nowPlaying.height()) + "px"
	  })
  } else {
  	nowPlaying.css({
	  	marginBottom: 0 + "px"
	  })
  }
 });

$('.button').on('click', function() {
  $(this).toggleClass('active');
});