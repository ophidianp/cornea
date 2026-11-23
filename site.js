/* Cornea website behaviour (every page): theme toggle, the header turning solid on scroll,
   the phone menu, the pinned feature stage, the first-visit preloader and the FAQ animation.
   The saved theme and the preloader flag are applied by a tiny inline script in each <head>. */
(() => {
  const root = document.documentElement;
  const $ = (id) => document.getElementById(id);
  const reduce = matchMedia("(prefers-reduced-motion: reduce)").matches;

  /* theme toggle, remembered per viewer */
  $("theme").addEventListener("click", () => {
    const dark = root.dataset.theme ? root.dataset.theme === "dark" : matchMedia("(prefers-color-scheme: dark)").matches;
    const next = dark ? "light" : "dark";
    const go = () => { root.dataset.theme = next; };
    document.startViewTransition && !reduce ? document.startViewTransition(go) : go();
    try { localStorage.setItem("cornea-theme", next); } catch (e) {}
  });

  /* phone menu */
  const hdr = $("hdr"), menu = $("menu"), mb = $("menu-btn");
  const setMenu = (open) => { menu.hidden = !open; mb.setAttribute("aria-expanded", open); hdr.classList.toggle("open", open); };
  mb.addEventListener("click", () => setMenu(menu.hidden));
  addEventListener("keydown", (e) => { if (e.key === "Escape" && !menu.hidden) { setMenu(false); mb.focus(); } });
  addEventListener("resize", () => { if (innerWidth > 880 && !menu.hidden) setMenu(false); });

  /* pinned feature stage: steps light up one by one and the picture follows */
  const tears = [...document.querySelectorAll(".tear")].map((sec) => {
    const steps = [...sec.querySelectorAll(".steps li")], layers = [...sec.querySelectorAll(".layer")];
    const lbl = sec.querySelector(".lbl"), bar = sec.querySelector(".bar i"), n = steps.length;
    let cur = -1;
    const set = (k) => {
      if (k === cur) return; cur = k;
      steps.forEach((s, i) => s.classList.toggle("on", i === k));
      layers.forEach((l, i) => l.classList.toggle("on", i === k));
      if (lbl && layers[k]) lbl.textContent = layers[k].dataset.tag;
    };
    steps.forEach((s, i) => s.addEventListener("click", () => {
      if (innerWidth <= 900) return;
      const max = sec.offsetHeight - innerHeight;
      scrollTo({ top: sec.offsetTop + max * (i + 0.5) / n, behavior: reduce ? "auto" : "smooth" });
    }));
    const update = () => {
      if (innerWidth <= 900) { bar.style.width = "0"; set(0); return; }
      const r = sec.getBoundingClientRect(), max = sec.offsetHeight - innerHeight;
      const p = Math.min(1, Math.max(0, -r.top / max));
      bar.style.width = (p * 100) + "%";
      set(Math.min(n - 1, Math.floor(p * n)));
    };
    return update;
  });

  /* header: solid after scroll, always visible */
  const onScroll = () => { hdr.classList.toggle("solid", scrollY > 10); tears.forEach((u) => u()); };
  addEventListener("scroll", onScroll, { passive: true });
  addEventListener("resize", onScroll);
  onScroll();

  /* FAQ: slide each answer open and closed instead of snapping */
  document.querySelectorAll(".faq details").forEach((d) => {
    const ans = d.querySelector(":scope > :not(summary)");
    let anim = null;
    d.querySelector("summary").addEventListener("click", (e) => {
      if (!ans || reduce) return;
      e.preventDefault();
      const opening = !d.open || d.classList.contains("closing");
      const from = d.open ? ans.offsetHeight : 0;
      if (anim) anim.cancel();
      d.open = true;
      d.classList.toggle("closing", !opening);
      const to = opening ? ans.scrollHeight : 0;
      anim = ans.animate([{ height: from + "px", opacity: opening ? 0 : 1 }, { height: to + "px", opacity: opening ? 1 : 0 }],
        { duration: opening ? 340 : 260, easing: "cubic-bezier(0.2, 0.7, 0.2, 1)" });
      anim.onfinish = () => { anim = null; if (!opening) { d.open = false; d.classList.remove("closing"); } };
    });
  });

  /* first-visit preloader: the logo fills in, then the page fades up */
  if (root.classList.contains("preload")) {
    let done = false;
    const finish = () => {
      if (done) return; done = true;
      root.classList.add("pre-done");
      setTimeout(() => root.classList.remove("preload", "pre-done"), 650);
    };
    const go = () => setTimeout(finish, Math.max(0, 1350 - performance.now()));
    document.readyState === "complete" ? go() : addEventListener("load", go);
    setTimeout(finish, 4000);
  }
})();
