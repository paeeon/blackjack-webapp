$(document).ready(function() {
  playerHits();
  playerStays();
  dealerHit();
})

function playerHits() {
  $(document).ready(function() {
    $(document).on('click', '#hit-form button', function() {
      $.ajax({
        type: 'POST',
        url: '/game/player/hit'
      }).done(function(msg) {
        $('#game').replaceWith(msg);
      });
      return false;
    });
  })
}

function playerStays() {
  $(document).ready(function() {
    $(document).on('click', '#stay-form button', function() {
      $.ajax({
        type: 'POST',
        url: '/game/player/stay'
      }).done(function(msg) {
        $('#game').replaceWith(msg);
      });
      return false;
    });
  })
}

function dealerHit() {
  $(document).ready(function() {
    $(document).on('click', '#dealer-hit input', function() {
      $.ajax({
        type: 'POST',
        url: '/game/dealer/hit'
      }).done(function(msg) {
        $('#game').replaceWith(msg);
      });
      return false;
    });
  })
}
