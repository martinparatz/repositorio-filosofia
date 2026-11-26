<script>
(function(){var b=document.getElementById('tema');if(!b)return;var r=document.documentElement;
try{var t=localStorage.getItem('tema');if(t)r.dataset.theme=t;}catch(e){}
b.onclick=function(){var d=r.dataset.theme?r.dataset.theme==='dark':matchMedia('(prefers-color-scheme:dark)').matches;
r.dataset.theme=d?'light':'dark';try{localStorage.setItem('tema',r.dataset.theme);}catch(e){}};})();
</script>
