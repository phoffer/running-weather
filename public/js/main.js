$(document ).ready(function() {
  // ZeroClipboard.config( { moviePath: '/js/ZeroClipboard.swf' } );
  // var client = new ZeroClipboard();

  // $(document).on('click', 'tr td', function(e) {
  //   alert($(this).text()); // this works! Let's go!
  //   client.setText($(this).text());
  //   alert($(this).text()); // this works! Let's go!
  // });
  $(document).on('click', '.get', function(e) {
    var run_id = $(this).parents('tr.run').attr('id');
    var url = $(this).attr('href').split("/")[1];
    // alert(url);
    // alert(run_id);
    $.ajax({
      type: "POST",
      url: "/" + url,
      data: {
        run_id: run_id
      },
      dataType: 'html',
      error: function(data) {
        alert(data);
      },
      success: function(data) {
        // alert(run_tr);
        // alert(data);
        // alert(run_tr.attr('id'));
        $('#'+run_id).html(data);
      }
    });
    return false;
    // $(this).slideUp();
  });
});
