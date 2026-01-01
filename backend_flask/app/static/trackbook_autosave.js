(function(){
  const container = document.querySelector("[data-trackbook='1']");
  if(!container) return;

  const termId = container.getAttribute("data-term-id");
  const status = document.querySelector("#trackStatus");
  let timer = null;

  function setStatus(txt){
    if(status) status.textContent = txt || "";
  }

  function payload(studentId){
    const absent = container.querySelector(".tb-absent[data-student-id='"+studentId+"']")?.value ?? "0";
    const permission = container.querySelector(".tb-permission[data-student-id='"+studentId+"']")?.value ?? "0";
    const note = container.querySelector(".tb-note[data-student-id='"+studentId+"']")?.value ?? "";
    return { student_id: studentId, term_id: termId, absent, permission, note };
  }

  async function save(studentId){
    const saving = status?.getAttribute("data-saving") || "កំពុងរក្សាទុក...";
    const saved = status?.getAttribute("data-saved") || "បានរក្សាទុក";
    setStatus("💾 " + saving);

    try{
      const res = await fetch("/teacher/trackbook/autosave", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload(studentId))
      });
      if(!res.ok){ setStatus("⚠️"); return; }
      await res.json();
      setStatus("✅ " + saved);
      setTimeout(()=>setStatus(""), 1200);
    }catch(e){
      setStatus("⚠️");
    }
  }

  function debounce(studentId){
    if(timer) clearTimeout(timer);
    timer = setTimeout(()=>save(studentId), 450);
  }

  container.querySelectorAll(".tb-absent, .tb-permission, .tb-note").forEach((el)=>{
    el.addEventListener("input", ()=>debounce(el.getAttribute("data-student-id")));
    el.addEventListener("blur", ()=>save(el.getAttribute("data-student-id")));
  });
})();
