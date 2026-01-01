(function(){
  const container = document.querySelector("[data-marks-autosave='1']");
  if(!container) return;

  const termId = container.getAttribute("data-term-id");
  const subjectId = container.getAttribute("data-subject-id");
  const status = document.querySelector("#autosaveStatus");

  let timer = null;
  let lastKey = null;

  function setStatus(text){
    if(status) status.textContent = text || "";
  }

  async function saveOne(input){
    const studentId = input.getAttribute("data-student-id");
    const score = (input.value || "").trim();
    const payload = { student_id: studentId, term_id: termId, subject_id: subjectId, score: score };

    const key = JSON.stringify(payload);
    if(key === lastKey) return;
    lastKey = key;

    const saving = status?.getAttribute("data-saving") || "Saving...";
    const saved = status?.getAttribute("data-saved") || "Saved";
    setStatus("💾 " + saving);

    try{
      const res = await fetch("/teacher/marks/autosave", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload)
      });
      if(!res.ok){ setStatus("⚠️"); return; }
      await res.json();
      setStatus("✅ " + saved);
      setTimeout(()=>setStatus(""), 1200);
    }catch(e){
      setStatus("⚠️");
    }
  }

  function debounce(input){
    if(timer) clearTimeout(timer);
    timer = setTimeout(()=>saveOne(input), 450);
  }

  container.querySelectorAll("input.mark-input").forEach((inp)=>{
    inp.addEventListener("input", ()=>debounce(inp));
    inp.addEventListener("blur", ()=>saveOne(inp));
  });
})();
