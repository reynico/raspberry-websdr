

var wfjavaid=0;

/**
 * @constructor
 */
function make_javawaterfall(w)
// creates an HTML canvas element inside the HTML div referred to by w.div
// then enhances that canvas object with lots of variables and functions to make it a waterfall "applet"
// returns the canvas object for future reference
{
   document.getElementById(w.div).innerHTML='<div>'+
      '<applet code="websdrwaterfall.class" align=top archive="websdr-1405020937.jar" width=1024 height='+waterheight+' name="waterfallapplet'+w.id+'" MAYSCRIPT>' +
      '<param name="rq" value="/~~waterstream'+bi[w.band].realband+'">' +
      '<param name="maxh" value="200">' +
      '<param name="maxzoom" value="' + bi[w.band].maxzoom + '">' +
      '<param name="id" value="'+w.id+'">' +
      '<\/applet>'+
      '<\/div>';
   var wfa=document["waterfallapplet"+w.id];

   w['setSize'] = function (w,h)
   { 
      wfa.height=h;
      wfa.setSize(1024,h);
      wfa.setheight(h);
   }

   w['destroy'] = function() 
   {
      wfa.destroy();
   }

   w['setzoom']= function(newzoom, newstart)
   {
      wfa.setzoom(newzoom,newstart);
   }

   w['setslow']=function (slow) { 
      wfa.setslow(slow); 
   }

   w['setmode']=function (m) { wfa.setmode(m); }

   w['setband']=function(new_band, new_maxzoom, new_zoom, new_start) 
   {
      wfa.setband(new_band, new_maxzoom, new_zoom, new_start);
   }

   return w;
}



window["prep_javawaterfalls"] = function()
{
   for (i=0;i<nwaterfalls;i++) {
      waterfallapplet[i]=make_javawaterfall(waterfallapplet[i]);
   }
}

prep_javawaterfalls();
