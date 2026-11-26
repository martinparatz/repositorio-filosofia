<script>
(function(){var i=document.getElementById('q');if(!i)return;
var norm=function(s){return s.normalize('NFD').replace(/[\u0300-\u036f]/g,'').toLowerCase();};
i.addEventListener('input',function(){var q=norm(i.value.trim()),n=0;
document.querySelectorAll('[data-buscar]').forEach(function(c){var ok=!q||norm(c.dataset.buscar).indexOf(q)>-1;c.hidden=!ok;if(ok)n++;});
document.querySelectorAll('.seccion[data-grupo]').forEach(function(s){s.hidden=!s.querySelector('[data-buscar]:not([hidden])');});
var v=document.getElementById('vacio');if(v)v.style.display=n?'none':'block';});})();
</script>
