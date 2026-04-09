const apiBase = "http://127.0.0.1:8000";

function token() {
  return localStorage.getItem("access_token");
}

function headers() {
  const h = { "Content-Type": "application/json" };
  if (token()) h.Authorization = `Bearer ${token()}`;
  return h;
}

async function post(path, body) {
  const res = await fetch(`${apiBase}${path}`, {
    method: "POST",
    headers: headers(),
    body: JSON.stringify(body),
  });
  const json = await res.json().catch(() => ({}));
  return { ok: res.ok, status: res.status, data: json };
}

async function get(path) {
  const res = await fetch(`${apiBase}${path}`, { headers: headers() });
  const json = await res.json().catch(() => ({}));
  return { ok: res.ok, status: res.status, data: json };
}

function el(id) {
  return document.getElementById(id);
}

function renderList(id, items, mapper) {
  const list = el(id);
  list.innerHTML = "";
  items.forEach((item) => {
    const li = document.createElement("li");
    li.innerHTML = mapper(item);
    list.appendChild(li);
  });
}

el("signupBtn").onclick = async () => {
  const email = el("email").value.trim();
  const password = el("password").value;
  const name = el("name").value.trim();
  const res = await post("/auth/signup", { email, password, name });
  el("authStatus").textContent = res.ok ? "Sign up successful" : `Sign up failed (${res.status})`;
};

el("loginBtn").onclick = async () => {
  const email = el("email").value.trim();
  const password = el("password").value;
  const res = await post("/auth/login", { email, password });
  if (res.ok && res.data.access_token) {
    localStorage.setItem("access_token", res.data.access_token);
    el("authStatus").textContent = "Logged in";
  } else {
    el("authStatus").textContent = `Login failed (${res.status})`;
  }
};

el("discoverBtn").onclick = async () => {
  const res = await get("/profiles/discover");
  if (!res.ok || !Array.isArray(res.data)) return;
  renderList(
    "discoverList",
    res.data,
    (p) => `
      <strong>${p.name || "Unknown"}</strong> (${p.score})
      <button data-like="${p.id}">Like</button>
      <button data-pass="${p.id}">Pass</button>
    `
  );
  document.querySelectorAll("[data-like]").forEach((btn) => {
    btn.onclick = async () => {
      await post("/matches/like", { target_user_id: Number(btn.dataset.like) });
      el("discoverBtn").click();
    };
  });
  document.querySelectorAll("[data-pass]").forEach((btn) => {
    btn.onclick = async () => {
      await post("/matches/pass", { target_user_id: Number(btn.dataset.pass) });
      el("discoverBtn").click();
    };
  });
};

el("matchesBtn").onclick = async () => {
  const res = await get("/matches/");
  if (!res.ok || !Array.isArray(res.data)) return;
  renderList(
    "matchesList",
    res.data,
    (m) => `Match #${m.id} users (${m.user_a_id}, ${m.user_b_id})`
  );
};

el("threadsBtn").onclick = async () => {
  const res = await get("/chat/threads");
  if (!res.ok || !Array.isArray(res.data)) return;
  renderList(
    "threadList",
    res.data,
    (t) => `<button data-thread="${t.id}">Thread #${t.id}</button>`
  );
  document.querySelectorAll("[data-thread]").forEach((btn) => {
    btn.onclick = async () => {
      el("threadId").value = btn.dataset.thread;
      const messages = await get(`/chat/threads/${btn.dataset.thread}/messages`);
      if (messages.ok && Array.isArray(messages.data)) {
        renderList(
          "messageList",
          messages.data,
          (m) => `[${m.sender_user_id}] ${m.content}`
        );
      }
    };
  });
};

el("sendMsgBtn").onclick = async () => {
  const threadId = Number(el("threadId").value);
  const content = el("messageText").value.trim();
  if (!threadId || !content) return;
  await post(`/chat/threads/${threadId}/messages`, { content });
  el("threadsBtn").click();
};
