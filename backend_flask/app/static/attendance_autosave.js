(function(){
  const container = document.querySelector("[data-marks-autosave='1']") || document;
  const termNode = document.querySelector("[data-marks-autosave='1']");
  const termId = termNode ? termNode.getAttribute("data-term-id") : null;
  if(!termId) return;

  let timer = null;
  const status = document.querySelector("#autosaveStatus");

  function setStatus(text){
    if(status) status.textContent = text || "";
  }

  function payload(studentId){
    const absent = document.querySelector(".att-absent[data-student-id='"+studentId+"']")?.value ?? "0";
    const permission = document.querySelector(".att-permission[data-student-id='"+studentId+"']")?.value ?? "0";
    return { student_id: studentId, term_id: termId, absent, permission, note: "" };
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
      setTimeout(()=>setStatus(""), 900);
    }catch(e){
      setStatus("⚠️");
    }
  }

  function debounce(studentId){
    if(timer) clearTimeout(timer);
    timer = setTimeout(()=>save(studentId), 400);
  }

  document.querySelectorAll(".att-absent, .att-permission").forEach((el)=>{
    el.addEventListener("input", ()=>debounce(el.getAttribute("data-student-id")));
    el.addEventListener("blur", ()=>save(el.getAttribute("data-student-id")));
  });
})();
