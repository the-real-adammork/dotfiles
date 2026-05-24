#!/usr/bin/env python3
"""Migrate legacy Markdown Linear workflow state into SQLite.

The parser is intentionally conservative: it imports deterministic fields from
known Markdown tables and current-state bullets, and records warnings whenever a
field is inferred or missing.
"""

from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import re
import shutil
import sqlite3
from pathlib import Path


TASK_RE = re.compile(r"^#{2,3}\s+Task\s+(\d+)\s*:\s*(.+?)\s*$", re.M)
MD_LINK_RE = re.compile(r"\[([^\]]+)\]\(([^)]+)\)")
def now() -> str:
    return dt.datetime.now(dt.timezone.utc).replace(microsecond=0).isoformat()


def slugify(value: str) -> str:
    value = value.lower()
    value = re.sub(r"[^a-z0-9]+", "-", value)
    return value.strip("-") or "workflow"


def read_text(path: Path | None) -> str:
    if not path:
        return ""
    return path.read_text(encoding="utf-8")


def sha256_text(value: str) -> str:
    return hashlib.sha256(value.encode("utf-8")).hexdigest()


def short_hash(value: str) -> str:
    return sha256_text(value)[:12]


def strip_md_cell(value: str) -> str:
    value = value.strip()
    if value.startswith("`") and value.endswith("`") and len(value) >= 2:
        return value[1:-1]
    match = MD_LINK_RE.search(value)
    if match:
        return match.group(2).strip()
    return value


def parse_md_tables(text: str) -> dict[str, list[dict[str, str]]]:
    tables: dict[str, list[dict[str, str]]] = {}
    current_heading = "Document"
    lines = text.splitlines()
    i = 0
    while i < len(lines):
        line = lines[i]
        heading = re.match(r"^(#{1,6})\s+(.+?)\s*$", line)
        if heading:
            current_heading = heading.group(2).strip()
            i += 1
            continue
        if "|" not in line or i + 1 >= len(lines) or not re.match(r"^\s*\|?\s*:?-{3,}:?", lines[i + 1]):
            i += 1
            continue
        headers = [h.strip() for h in line.strip().strip("|").split("|")]
        i += 2
        rows: list[dict[str, str]] = []
        while i < len(lines) and "|" in lines[i] and lines[i].strip():
            cells = [strip_md_cell(c) for c in lines[i].strip().strip("|").split("|")]
            if len(cells) < len(headers):
                cells.extend([""] * (len(headers) - len(cells)))
            rows.append(dict(zip(headers, cells)))
            i += 1
        tables[current_heading] = rows
    return tables


def parse_current_state(text: str) -> dict[str, str]:
    state: dict[str, str] = {}
    match = re.search(r"## Current State\s*\n(?P<body>.*?)(?:\n## |\Z)", text, re.S)
    if not match:
        return state
    for line in match.group("body").splitlines():
        item = re.match(r"^-\s+([^:]+):\s*(.+?)\s*$", line)
        if item:
            state[item.group(1).strip()] = strip_md_cell(item.group(2))
    return state


def parse_event_log(text: str) -> list[tuple[str, str]]:
    match = re.search(r"## Event Log\s*\n(?P<body>.*?)(?:\n## |\Z)", text, re.S)
    if not match:
        return []
    events = []
    for line in match.group("body").splitlines():
        event = re.match(r"^-\s+`?([^`]+?)`?\s+-\s+(.+?)\s*$", line.strip())
        if event:
            events.append((event.group(1).strip(), event.group(2).strip()))
    return events


def discover_plan_paths(slices_path: Path, ledger_text: str) -> list[Path]:
    candidates: list[str] = []
    for text in [read_text(slices_path), ledger_text]:
        for _, href in MD_LINK_RE.findall(text):
            if href.endswith(".md") and "review" not in href.lower():
                candidates.append(href.split("#", 1)[0])
        for path in re.findall(r"`([^`]+\.md)(?:#[^`]*)?`", text):
            if "review" not in path.lower():
                candidates.append(path.split("#", 1)[0])
    out: list[Path] = []
    seen: set[str] = set()
    base = slices_path.parent
    for raw in candidates:
        path = Path(raw)
        if not path.is_absolute():
            path = (base / path).resolve() if not Path(raw).exists() else Path(raw).resolve()
        key = str(path)
        if key not in seen and path.exists() and path != slices_path.resolve():
            seen.add(key)
            out.append(path)
    return out


def parse_plan(path: Path) -> dict:
    text = read_text(path)
    title_match = re.search(r"^#\s+(.+?)\s*$", text, re.M)
    title = title_match.group(1).strip() if title_match else path.stem.replace("-", " ").title()
    tasks = []
    matches = list(TASK_RE.finditer(text))
    for index, match in enumerate(matches):
        start = match.start()
        end = matches[index + 1].start() if index + 1 < len(matches) else len(text)
        section = text[start:end]
        number = match.group(1)
        task_title = match.group(2).strip()
        anchor = f"task-{number}-{slugify(task_title)}"
        tasks.append(
            {
                "number": number,
                "title": task_title,
                "anchor": anchor,
                "source_hash": sha256_text(section),
            }
        )
    return {
        "path": path,
        "title": title,
        "slug": slugify(title),
        "source_hash": sha256_text(text),
        "tasks": tasks,
    }


def extract_ledger_mappings(ledger_text: str) -> tuple[dict[str, dict], dict[str, dict], list[str]]:
    warnings: list[str] = []
    projects: dict[str, dict] = {}
    issues: dict[str, dict] = {}
    tables = parse_md_tables(ledger_text)
    for row in tables.get("Projects", []):
        plan = row.get("Plan") or row.get("Source Plan") or ""
        if not plan:
            continue
        projects[plan.split("#", 1)[0]] = {
            "name": row.get("Linear Project") or row.get("Project") or "",
            "url": row.get("Linear URL") or row.get("URL") or "",
            "sync_key": row.get("Sync Key") or "",
            "branch": row.get("Branch") or "",
            "worktree": row.get("Worktree") or "",
        }
    for row in tables.get("Issues", []):
        source = row.get("Task Source") or row.get("Source") or ""
        if not source:
            continue
        issues[source] = {
            "issue": row.get("Linear Issue") or row.get("Issue") or "",
            "url": row.get("Linear URL") or row.get("URL") or "",
            "status": row.get("Status") or "",
            "assignee": row.get("Assignee") or "",
            "sync_key": row.get("Sync Key") or "",
            "source_hash": row.get("Source Hash") or "",
        }
    if not projects:
        warnings.append("No Projects table was imported from the ledger.")
    if not issues:
        warnings.append("No Issues table was imported from the ledger.")
    return projects, issues, warnings


def init_schema(conn: sqlite3.Connection) -> None:
    conn.executescript(
        """
        create table if not exists workflow_runs (
          id text primary key,
          feature_slug text,
          status text,
          state_backend text not null default 'sqlite',
          slices_document text,
          sync_ledger text,
          supervisor_run_log text,
          config_path text,
          active_plan_id text,
          active_task_id text,
          restart_action text,
          legacy_state_mode text,
          created_at text not null,
          updated_at text not null
        );

        create table if not exists plans (
          id text primary key,
          run_id text not null,
          order_index integer,
          plan_path text not null,
          plan_title text,
          plan_slug text,
          linear_project_name text,
          linear_project_url text,
          linear_project_sync_key text,
          status text,
          worktree text,
          branch text,
          source_hash text,
          legacy_source text,
          created_at text not null,
          updated_at text not null
        );

        create table if not exists tasks (
          id text primary key,
          plan_id text not null,
          task_number text,
          task_title text,
          task_anchor text,
          source_ref text,
          linear_issue text,
          linear_issue_url text,
          linear_issue_sync_key text,
          status text,
          assignee text,
          source_hash text,
          last_commit text,
          legacy_source text,
          created_at text not null,
          updated_at text not null
        );

        create table if not exists agents (
          id integer primary key autoincrement,
          run_id text not null,
          stable_agent_name text,
          host_agent_id text,
          role text,
          plan_id text,
          task_id text,
          status text,
          notes text,
          legacy_source text,
          created_at text not null,
          updated_at text not null
        );

        create table if not exists events (
          id integer primary key autoincrement,
          run_id text not null,
          plan_id text,
          task_id text,
          event_time text not null,
          actor text,
          event_type text,
          message text not null,
          payload_json text,
          legacy_source text
        );

        create table if not exists artifacts (
          id integer primary key autoincrement,
          run_id text not null,
          plan_id text,
          task_id text,
          kind text,
          path text not null,
          source text,
          archived_path text,
          created_at text not null
        );

        create table if not exists human_reviews (
          id integer primary key autoincrement,
          run_id text not null,
          task_id text,
          linear_issue text,
          status text,
          smoke_test_path text,
          waiting_since text,
          timeout_at text,
          approved_at text,
          legacy_source text,
          created_at text not null,
          updated_at text not null
        );

        create table if not exists consistency_queue (
          id integer primary key autoincrement,
          run_id text not null,
          plan_id text,
          task_id text,
          linear_issue text,
          task_number text,
          merge_back_commit text,
          actual_summary text,
          changed_files_json text,
          status text not null default 'pending',
          skipped_active_tasks_json text,
          coordination_findings_json text,
          consistency_commit text,
          created_at text not null,
          updated_at text not null
        );

        create table if not exists source_hashes (
          source_ref text primary key,
          source_hash text not null,
          kind text,
          updated_at text not null
        );
        """
    )


def upsert(conn: sqlite3.Connection, table: str, values: dict) -> None:
    keys = list(values)
    placeholders = ", ".join("?" for _ in keys)
    columns = ", ".join(keys)
    updates = ", ".join(f"{k}=excluded.{k}" for k in keys if k != "id")
    conn.execute(
        f"insert into {table} ({columns}) values ({placeholders}) "
        f"on conflict(id) do update set {updates}",
        [values[k] for k in keys],
    )


def write_report(path: Path, summary: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    warnings = summary["warnings"] or ["None"]
    lines = [
        f"# Linear State Migration: {summary['run_id']}",
        "",
        f"State DB: `{summary['db']}`",
        f"Slices document: `{summary['slices']}`",
        f"Legacy sync ledger: `{summary['ledger']}`",
        f"Legacy supervisor run log: `{summary.get('supervisor_run_log') or 'None'}`",
        f"Archived legacy state: `{summary.get('archive_dir') or 'not archived'}`",
        "",
        "## Imported",
        "",
        f"- Plans: {summary['plans']}",
        f"- Tasks: {summary['tasks']}",
        f"- Linear projects: {summary['linear_projects']}",
        f"- Linear issues: {summary['linear_issues']}",
        f"- Events: {summary['events']}",
        "",
        "## Active State",
        "",
        f"- Status: {summary.get('status') or 'unknown'}",
        f"- Active plan: `{summary.get('active_plan') or 'none'}`",
        f"- Active task: `{summary.get('active_task') or 'none'}`",
        f"- Restart action: {summary.get('restart_action') or 'none'}",
        "",
        "## Warnings",
        "",
    ]
    lines.extend(f"- {warning}" for warning in warnings)
    lines.append("")
    path.write_text("\n".join(lines), encoding="utf-8")


def archive_files(files: list[Path], archive_dir: Path) -> dict[str, str]:
    archive_dir.mkdir(parents=True, exist_ok=True)
    moved: dict[str, str] = {}
    for src in files:
        if not src or not src.exists():
            continue
        dest = archive_dir / src.name
        suffix = 1
        while dest.exists():
            dest = archive_dir / f"{src.stem}-{suffix}{src.suffix}"
            suffix += 1
        shutil.move(str(src), str(dest))
        moved[str(src)] = str(dest)
    return moved


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--db", default=".codex/workflows/state.sqlite")
    parser.add_argument("--slices", required=True)
    parser.add_argument("--ledger", required=True)
    parser.add_argument("--supervisor-run-log")
    parser.add_argument("--orchestrator-run-log", action="append", default=[])
    parser.add_argument("--config", default=".codex/linear.toml")
    parser.add_argument("--run-id")
    parser.add_argument("--feature-slug")
    parser.add_argument("--report")
    parser.add_argument("--archive-dir")
    parser.add_argument("--archive", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    db_path = Path(args.db)
    slices_path = Path(args.slices)
    ledger_path = Path(args.ledger)
    supervisor_path = Path(args.supervisor_run_log) if args.supervisor_run_log else None
    orchestrator_paths = [Path(p) for p in args.orchestrator_run_log]

    warnings: list[str] = []
    ledger_text = read_text(ledger_path)
    supervisor_text = read_text(supervisor_path)
    supervisor_state = parse_current_state(supervisor_text)
    feature_slug = args.feature_slug or slugify(slices_path.stem.replace("implementation-slices", "").strip("-"))
    run_id = args.run_id or f"{feature_slug}-{short_hash(str(slices_path.resolve()))}"
    report_path = Path(args.report) if args.report else Path("docs/linear/migrations") / f"{dt.date.today().isoformat()}-{feature_slug}-state-migration.md"
    archive_dir = Path(args.archive_dir) if args.archive_dir else Path("docs/linear/legacy-state") / run_id

    plan_paths = discover_plan_paths(slices_path, ledger_text)
    if not plan_paths:
        warnings.append("No plan paths were discovered from the slices document or ledger.")
    plans = [parse_plan(path) for path in plan_paths]
    projects, issues, ledger_warnings = extract_ledger_mappings(ledger_text)
    warnings.extend(ledger_warnings)

    event_count = 0
    if not args.dry_run:
        db_path.parent.mkdir(parents=True, exist_ok=True)
        conn = sqlite3.connect(db_path)
        init_schema(conn)
        timestamp = now()
        active_plan_id = None
        active_task_id = None

        upsert(
            conn,
            "workflow_runs",
            {
                "id": run_id,
                "feature_slug": feature_slug,
                "status": supervisor_state.get("status") or "imported",
                "state_backend": "sqlite",
                "slices_document": str(slices_path),
                "sync_ledger": str(ledger_path),
                "supervisor_run_log": str(supervisor_path) if supervisor_path else "",
                "config_path": args.config,
                "active_plan_id": "",
                "active_task_id": "",
                "restart_action": supervisor_state.get("restart_action") or "",
                "legacy_state_mode": "imported",
                "created_at": timestamp,
                "updated_at": timestamp,
            },
        )

        for order, plan in enumerate(plans, start=1):
            plan_key = str(plan["path"])
            mapping = projects.get(plan_key) or projects.get(plan["path"].name) or {}
            plan_id = f"{run_id}:plan:{order}:{slugify(plan['title'])}"
            if supervisor_state.get("active_plan") and supervisor_state["active_plan"] in plan_key:
                active_plan_id = plan_id
            upsert(
                conn,
                "plans",
                {
                    "id": plan_id,
                    "run_id": run_id,
                    "order_index": order,
                    "plan_path": str(plan["path"]),
                    "plan_title": plan["title"],
                    "plan_slug": plan["slug"],
                    "linear_project_name": mapping.get("name", ""),
                    "linear_project_url": mapping.get("url", ""),
                    "linear_project_sync_key": mapping.get("sync_key", ""),
                    "status": "imported",
                    "worktree": mapping.get("worktree", ""),
                    "branch": mapping.get("branch", ""),
                    "source_hash": plan["source_hash"],
                    "legacy_source": str(ledger_path),
                    "created_at": timestamp,
                    "updated_at": timestamp,
                },
            )
            conn.execute(
                "insert or replace into source_hashes values (?, ?, ?, ?)",
                (str(plan["path"]), plan["source_hash"], "plan", timestamp),
            )
            for task in plan["tasks"]:
                source_ref = f"{plan['path']}#{task['anchor']}"
                issue_mapping = issues.get(source_ref) or next(
                    (v for k, v in issues.items() if k.endswith(f"#{task['anchor']}") or task["title"] in k),
                    {},
                )
                task_id = f"{plan_id}:task:{task['number']}"
                if supervisor_state.get("active_task") and task["title"] in supervisor_state["active_task"]:
                    active_task_id = task_id
                upsert(
                    conn,
                    "tasks",
                    {
                        "id": task_id,
                        "plan_id": plan_id,
                        "task_number": task["number"],
                        "task_title": task["title"],
                        "task_anchor": task["anchor"],
                        "source_ref": source_ref,
                        "linear_issue": issue_mapping.get("issue", ""),
                        "linear_issue_url": issue_mapping.get("url", ""),
                        "linear_issue_sync_key": issue_mapping.get("sync_key", ""),
                        "status": issue_mapping.get("status", "imported"),
                        "assignee": issue_mapping.get("assignee", ""),
                        "source_hash": issue_mapping.get("source_hash") or task["source_hash"],
                        "last_commit": "",
                        "legacy_source": str(ledger_path),
                        "created_at": timestamp,
                        "updated_at": timestamp,
                    },
                )
                conn.execute(
                    "insert or replace into source_hashes values (?, ?, ?, ?)",
                    (source_ref, task["source_hash"], "task", timestamp),
                )

        for log_path in [supervisor_path, *orchestrator_paths]:
            if not log_path:
                continue
            log_text = read_text(log_path)
            for event_time, message in parse_event_log(log_text):
                conn.execute(
                    "insert into events (run_id, event_time, actor, event_type, message, payload_json, legacy_source) values (?, ?, ?, ?, ?, ?, ?)",
                    (run_id, event_time, "legacy-import", "legacy_event", message, "{}", str(log_path)),
                )
                event_count += 1
            conn.execute(
                "insert into artifacts (run_id, kind, path, source, created_at) values (?, ?, ?, ?, ?)",
                (run_id, "legacy_run_log", str(log_path), "legacy_import", timestamp),
            )

        conn.execute(
            "update workflow_runs set active_plan_id = ?, active_task_id = ?, updated_at = ? where id = ?",
            (active_plan_id or "", active_task_id or "", timestamp, run_id),
        )
        conn.commit()
        conn.close()

    legacy_files = [ledger_path]
    if supervisor_path:
        legacy_files.append(supervisor_path)
    legacy_files.extend(orchestrator_paths)
    archived: dict[str, str] = {}
    if args.archive and not args.dry_run:
        archived = archive_files(legacy_files, archive_dir)

    summary = {
        "run_id": run_id,
        "db": str(db_path),
        "slices": str(slices_path),
        "ledger": str(ledger_path),
        "supervisor_run_log": str(supervisor_path) if supervisor_path else "",
        "archive_dir": str(archive_dir) if archived else "",
        "plans": len(plans),
        "tasks": sum(len(plan["tasks"]) for plan in plans),
        "linear_projects": len(projects),
        "linear_issues": len(issues),
        "events": event_count,
        "status": supervisor_state.get("status") or "unknown",
        "active_plan": supervisor_state.get("active_plan") or "",
        "active_task": supervisor_state.get("active_task") or "",
        "restart_action": supervisor_state.get("restart_action") or "",
        "warnings": warnings,
        "archived": archived,
    }

    if not args.dry_run:
        write_report(report_path, summary)
    summary["report"] = str(report_path)
    print(json.dumps(summary, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
