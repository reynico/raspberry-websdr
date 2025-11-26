

/**
 * @constructor
 */
function make_javasound()
{
   document.getElementById('soundappletdiv').innerHTML=
     '<applet code="websdrsound.class" archive="websdr-1405020937.jar" width=400 height=100 name="javasoundapplet" MAYSCRIPT>' +
     '<\/applet>' +
     '\n';

   try {
      var sa=document["javasoundapplet"];
      this['setparam'] = function(s) { sa.setparam(s); }
      this['smeter'] = function () { return sa.smeter; }
      this['getid'] = function () { return sa.getid(); }
      this['setvolume'] = function (v) { sa.setvolume(v); }
      this['destroy'] = function() { sa.destroy(); }
      this['javaversion'] = function() { sa.javaversion(); }
      this['app'] = sa;
   } catch (e) {};
}


window["prep_javasound"] = function()
{
   window['soundapplet']=new make_javasound();
}

prep_javasound();
