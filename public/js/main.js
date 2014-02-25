$(document ).ready(function() {
  // function getData(element) {
  //   var run_id = element.parents('tr.run').attr('id');
  //   var url    = element.attr('href').split("/")[1];
  //   $.ajax({
  //     type: "POST",
  //     url: "/" + url,
  //     data: {
  //       run_id: run_id
  //     },
  //     dataType: 'html',
  //     error: function(data) {
  //       alert(data);
  //     },
  //     success: function(data) {
  //       $('#'+run_id).html(data);
  //       $('#'+run_id).
  //     }
  //   });
  //   return false;
  // }
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
