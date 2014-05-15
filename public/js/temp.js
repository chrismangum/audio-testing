var toggleNowPlaying = $('.now-playing .sidebar-title'),
    nowPlayingButton = $('.now-playing-button');
    nowPlayingArtwork = $('.now-playing-artwork');

toggleNowPlaying.on('click', function() {
  nowPlayingButton.toggleClass('flip-icon');
  nowPlayingArtwork.toggleClass('now-playing-hide');
  if (nowPlayingArtwork.hasClass('now-playing-hide')) {
    nowPlayingArtwork.css({
      marginBottom: -(nowPlayingArtwork.height()) + 'px'
    });
  } else {
    nowPlayingArtwork.css({
      marginBottom: 0 + 'px'
    });
  }
});