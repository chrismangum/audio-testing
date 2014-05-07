var toggleNowPlaying = $('.toggle-now-playing'),
    nowPlaying = $('.now-playing');

$(window).on('resize', function() {
  $('.main').css({
    height: $(window).height() + 'px'
  });
}).resize();


toggleNowPlaying.on('click', function() {
  $(this).toggleClass('flip-icon');
  nowPlaying.toggleClass('now-playing-hide');
  if (nowPlaying.hasClass('now-playing-hide')) {
    nowPlaying.css({
      marginBottom: -(nowPlaying.height()) + 'px'
    });
  } else {
    nowPlaying.css({
      marginBottom: 0 + 'px'
    });
  }
});
