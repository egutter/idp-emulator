$(document).ready(function() {
  $('select#environment').change(function(e){
    if($('select#environment').val() == "ch.localhost"){
      $('input#port').val("3000");
    } else if($('select#environment').val() == "merge.connectedhealth.com"){
      $('input#port').val("8080");
    } else{
      $('input#port').val("80");
    }
  });
});
