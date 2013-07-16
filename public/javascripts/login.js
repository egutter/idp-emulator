$(document).ready(function() {

    $('select#environment').change(function(e){
	if($('select#environment').val() == "ch.localhost:"){
	    $('input#port').val("3000");
	}
	else{
	    $('input#port').val("80");
	}
    });

});
