// Toggle Now Playing Artwork
var resizeArtwork = $('.resize-artwork');
    nowPlayingArtworkLarge = $('.now-playing-artwork-large');
    nowPlayingArtworkSmall = $('.now-playing-artwork-small')

resizeArtwork.on('click', function() {
  nowPlayingArtworkLarge.addClass('hide-artwork');
  nowPlayingArtworkSmall.removeClass('hide-artwork');
});

nowPlayingArtworkSmall.on('click', function() {
  $(this).addClass('hide-artwork');
  nowPlayingArtworkLarge.removeClass('hide-artwork');
});