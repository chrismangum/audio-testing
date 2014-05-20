// Google Web Fonts
WebFontConfig = {
  google: { families: [ 'Cabin+Condensed:400,700:latin' ] }
};
(function() {
  var wf = document.createElement('script');
  wf.src = ('https:' == document.location.protocol ? 'https' : 'http') +
    '://ajax.googleapis.com/ajax/libs/webfont/1/webfont.js';
  wf.type = 'text/javascript';
  wf.async = 'true';
  var s = document.getElementsByTagName('script')[0];
  s.parentNode.insertBefore(wf, s);
})();

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