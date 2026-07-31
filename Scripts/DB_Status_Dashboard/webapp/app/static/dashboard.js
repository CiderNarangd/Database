const POLL_INTERVAL_MS = 30000;

function applyCheck(row, fieldPrefix, check) {
  const badge = row.querySelector(`[data-field="${fieldPrefix}-status"]`);
  if (!badge) return;
  const status = check ? check.status : "unknown";
  badge.textContent = status;
  badge.className = `badge status-${status}`;
}

function updateRow(row, host) {
  const svc = host.checks.service;
  const repl = host.checks.replication;

  applyCheck(row, "service", svc);
  applyCheck(row, "replication", repl);

  const checkedAtEl = row.querySelector('[data-field="checked-at"]');
  if (checkedAtEl) {
    checkedAtEl.textContent = svc ? svc.checked_at : "-";
    checkedAtEl.classList.toggle("stale", Boolean(svc && svc.is_stale));
  }
}

async function refreshTable(table) {
  try {
    const res = await fetch(table.dataset.api);
    if (!res.ok) return;
    const data = await res.json();
    for (const host of data.hosts) {
      const row = table.querySelector(`tr[data-hostname="${host.hostname}"]`);
      if (row) updateRow(row, host);
    }
  } catch (err) {
    console.error("status refresh failed", err);
  }
}

function initPolling() {
  document.querySelectorAll(".status-table").forEach((table) => {
    setInterval(() => refreshTable(table), POLL_INTERVAL_MS);
  });
}

function initFilterButtons() {
  const buttons = document.querySelectorAll(".filter-btn");
  const panels = document.querySelectorAll(".panel[data-db-type]");

  buttons.forEach((btn) => {
    btn.addEventListener("click", () => {
      buttons.forEach((b) => b.classList.remove("is-active"));
      btn.classList.add("is-active");

      const filter = btn.dataset.filter;
      panels.forEach((panel) => {
        const show = filter === "all" || panel.dataset.dbType === filter;
        panel.style.display = show ? "" : "none";
      });
    });
  });
}

initPolling();
initFilterButtons();
