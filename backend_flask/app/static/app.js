document.addEventListener("change", (e) => {
  const el = e.target;
  const form = el && el.closest("form");
  if (form && form.dataset.autosubmit === "true") {
    form.requestSubmit();
  }
});
