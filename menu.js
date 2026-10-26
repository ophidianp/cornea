
  /* ---------- Mobile menu ---------- */
  const menuBtn = document.getElementById("menu-toggle");
  const menuNav = document.getElementById("nav");
  if (menuBtn && menuNav) {
    const setMenu = (open) => {
      menuBtn.setAttribute("aria-expanded", open);
      menuBtn.setAttribute("aria-label", open ? "Close menu" : "Open menu");
      menuNav.classList.toggle("is-open", open);
    };
    menuBtn.addEventListener("click", () => setMenu(menuBtn.getAttribute("aria-expanded") !== "true"));
    menuNav.addEventListener("click", (e) => { if (e.target.closest("a")) setMenu(false); });
    document.addEventListener("keydown", (e) => { if (e.key === "Escape") setMenu(false); });
    document.addEventListener("pointerdown", (e) => {
      if (menuBtn.getAttribute("aria-expanded") === "true" && !e.target.closest("#nav, #menu-toggle")) setMenu(false);
    });
    addEventListener("resize", () => { if (innerWidth > 860) setMenu(false); });
  }
