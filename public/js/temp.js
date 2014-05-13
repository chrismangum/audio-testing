var toggleNowPlaying = $('.now-playing-container .sidebar-title'),
    nowPlayingButton = $('.now-playing-button');
    nowPlaying = $('.now-playing');

$(window).on('resize', function() {
  $('.main').css({
    height: $(window).height() + 'px'
  });
}).resize();


toggleNowPlaying.on('click', function() {
  nowPlayingButton.toggleClass('flip-icon');
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

$('.dropdown-toggle').on('click', function() {
  $('.dropdown').toggleClass('show');
});

$('.volume-slider').noUiSlider({
  start: 0,
  orientation: 'vertical',
  connect: 'lower',
  range: {
    'min': 0,
    'max': 100
  }
})