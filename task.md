# GrantAxis Sprint Tasks

## Sprint Overview
This sprint focuses on implementing the core "Run Free Scan" functionality of GrantAxis, leveraging Titan's Snowflake-IaC engine. The sprint is designed to deliver a working MVP that can scan Snowflake environments for access-right drift.

## Three-Week "Run Free Scan" Sprint — Work Breakdown Structure

*(Every line is an indivisible unit a single dev can complete in < 4 h. Slack updates at EOD mandatory.)*

---

## **EPIC 0: Repo & Licensing Hygiene (Day 0)**

| #   | Task                                                                                              | Output                           |
| --- | ------------------------------------------------------------------------------------------------- | -------------------------------- |
| 0.1 | Add Titan code: move all files into `third_party/titan_core`                                       | ✅ All files in titan_core        |
| 0.2 | Copy Titan LICENSE → `/third_party/titan_core/LICENSE`                                             | ✅ File exists in repo            |
| 0.3 | Create empty `/third_party/titan_core/NOTICE`                                                      | ✅ Placeholder file               |
| 0.4 | Add SPDX line to root README explaining Apache-2.0 compliance                                      | ✅ README diff                    |
| 0.5 | Add CI step (`check-notice.sh`) that fails if upstream NOTICE gains >0 bytes                       | ✅ Failing test proves guard      |
| 0.6 | Create `/legal/third-party.html` auto-rendered from SPDX headers                                   | ✅ Page renders in website build  |
| 0.7 | Rename CLI wrapper to `grantaxis-titan` in all docs                                                | ✅ No "Official Titan SaaS" mentions|

---

## **EPIC 1: Titan Worker Container (Days 0-2)**

| #   | Task                                                                                                                             | Output                                |
| --- | -------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------- |
| 1.1 | Write `Dockerfile.titan-worker` multi-stage build (python:3.12-slim)                                                             | ✅ Image builds locally                |
| 1.2 | Install Titan CLI inside container: `pip install -e third_party/titan_core`                                                      | ✅ `titan --help` runs in container    |
| 1.3 | Add tini & non-root user; set ENTRYPOINT `/runner.sh`                                                                            | ✅ Security baseline                   |
| 1.4 | Create `/runner.sh` that: <br>• pulls job env vars <br>• injects AWS credentials via `AWS_WEB_IDENTITY_TOKEN_FILE` or secrets-manager env injection (no file copies) <br>• runs titan export → plan → uploads plan.json |                                 |
| 1.5 | Unit test container via `docker run -e DRY_RUN=1` to ensure dependencies only 200 MB                                             |                                 |
| 1.6 | Implement timeout handling (8 min max runtime)                                                                                   |                                 |
| 1.7 | Stream logs to stdout as JSON for CloudWatch aggregation                                                                        |                                 |
| 1.8 | Unit test SIGTERM handling — ensure pod exits 137, not hung                                                                     |                                 |

---

## **EPIC 2: Backend Skeleton (Days 3-5)**

| #   | Task                                                                                                                          | Output                       |
| --- | ----------------------------------------------------------------------------------------------------------------------------- | ---------------------------- |
| 2.1 | Scaffold FastAPI project `apps/api` with Poetry <br>• Pin FastAPI + Uvicorn versions to avoid 0.110 breaking change             |                                 |
| 2.2 | Implement `/healthz` GET returning `200 OK`                                                                                   |                                 |
| 2.3 | Define DB schema in Alembic: `scan_jobs` table (id, tenant_id, status, baseline_url, plan_url, summary_json, created_at) <br>• Include `tenant_id → UNIQUE` index      |                                 |
| 2.4 | Add PostgreSQL service in `docker-compose.yml` with volume <br>• `docker compose up` starts and `psql` connects                |                                 |
| 2.5 | Implement POST `/scans` that inserts row (status=PENDING) and pushes message to RabbitMQ `scan_queue` <br>• Validation schema (Pydantic) <br>• Generate presigned S3 URL for policy upload if CSV large <br>• Return `job_id` + `upload_url` |                                 |
| 2.6 | Implement GET `/scans/{id}` returning row JSON <br>• Add pagination stub for future `/scans?tenant=` list                      |                                 |
| 2.7 | Add `MessagePublisher` util wrapping pika; publish `job_id` <br>• Unit test publishes and consumes in mocked RabbitMQ           |                                 |
| 2.8.1 | Write compose service & network                                                                                              |                                 |
| 2.8.2 | Write consumer script that shells out                                                                                         |                                 |
| 2.8.3 | Integration test end-to-end                                                                                                  |                                 |
| 2.8.4 | Make explicit: compose file maps docker socket OR uses Docker-in-Docker                                                      |                                 |
| 2.9 | Webhook endpoint `/internal/scan_done` that updates row with S3 URLs & summary <br>• Verify HMAC token to block spoofed calls  |                                 |

---

## **EPIC 3: Policy Adapters & Schema (Days 6-8)**

| #   | Task                                                                                                             | Output                            |
| --- | ---------------------------------------------------------------------------------------------------------------- | --------------------------------- |
| 3.1 | Draft JSON schema `policy.schema.json` with `objects[]`, `roles[]`, enum validation                              | Stored in `apps/api/schemas`      |
| 3.2 | Implement `BaseAdapter` class with `fetch_policy()` abstractmethod                                               | Unit tests pass                   |
| 3.3 | **TagsAdapter**: queries ACCOUNT_USAGE.TAG_REFERENCES via Snowflake connector mock; returns policy JSON <br>• Add real integration test later |                                 |
| 3.4 | **ConventionAdapter**: regex derive security level from role names; param `regex` defaults to `PRD_…_(TRUSTED\|RESTRICTED)` | Unit tests 5 cases |
| 3.5 | **CsvAdapter**: parse user-supplied CSV into policy JSON; raises on bad headers                                  | CSV fixture test                  |
| 3.6 | Write adapter auto-detector: tries tags → convention; if fail returns `None`                                     | Tested with tagless dataset       |
| 3.7 | Serialize policy JSON to `policy.yaml` (Titan's expected format) using `ruamel.yaml` <br>• Unit test invalid char escaping    |                                 |

---

## **EPIC 4: CLI v0.1 (Days 9-11)**

| #   | Task                                                                          | Output              |
| --- | ----------------------------------------------------------------------------- | ------------------- |
| 4.1 | Scaffold `grantaxis-cli` with Typer                                           | `grantaxis --help`  |
| 4.2 | Implement `scan` command: collects args, zips credentials, encrypts ZIP with `fernet` before POST, hits POST `/scans`         |                                 |
| 4.3 | Poll `/scans/{id}` every 5 s until status ≠ PENDING                           | Progress bar prints |
| 4.4 | On completion: download plan.json S3 link, pretty-print summary table         | Rendered            |
| 4.5 | `--local` flag: run adapters and diff locally without API (mock Titan)        | Offline test        |
| 4.6 | Publish CLI to TestPyPI; pin SHA256 in docs <br>• Version bump CI action                                                      |                                 |

---

## **EPIC 5: PDF Reporter (Days 12-14)**

| #   | Task                                                                | Output                     |
| --- | ------------------------------------------------------------------- | -------------------------- |
| 5.1 | Create Jinja2 template `report.html` with table + severity heat bar | Template renders           |
| 5.2 | Use WeasyPrint to convert HTML → PDF inside API worker <br>• If system deps (pango, cairo) are too large, use separate lightweight reporter container or switch to pdfkit + wkhtmltopdf-alpine |                                 |
| 5.3 | Store PDF in S3 `s3://reports/{tenant}/yyyy/mm/{scan_id}.pdf`                                                                  |                                 |
| 5.4 | Update webhook to include `report_url` in DB                        | Field populated            |
| 5.5 | CLI: if `--pdf` flag, auto-open link post scan (macOS `open`)       | Works on test Mac          |
| 5.6 | Landing page dashboard link to PDF for completed scans              | Link visible               |

---

## **EPIC 6: Landing Page Hook-Up (Days 15-18)**

| #   | Task                                                                                           | Output                   |
| --- | ---------------------------------------------------------------------------------------------- | ------------------------ |
| 6.1 | Add "Install CLI" section with copy button (`brew install pipx && pipx install grantaxis-cli`) | Copy event tracked       |
| 6.2 | Embed the 6-line SQL block with syntax highlight + "Copy SQL"                                  | Clipboard works          |
| 6.3 | Add code-snippet toggler for Linux / Windows PowerShell                                        | UI toggle                |
| 6.4 | Capture `scan_started` event via PostHog from click on copy button                             | Event shows in dashboard |
| 6.5 | Success modal that polls `/scans/{id}` via SSE and confetti when status=COMPLETED              | Works local              |
| 6.6 | 404 page for invalid job_id                                                                   | Tested                   |
| 6.7 | Accessibility check (axe-core) as lint step                                                                                   |                                 |

---

## **EPIC 7: Closed Alpha Roll-Out (Days 19-21)**

| #   | Task                                                                      | Output            |
| --- | ------------------------------------------------------------------------- | ----------------- |
| 7.1 | Provision isolated Snowflake dev account for test                         | Account ready     |
| 7.2 | Create scan role SQL & user for partner #1                                | Credentials sent  |
| 7.3 | Walk partner through CLI install on Zoom, record session                  | Recording         |
| 7.4 | Collect runtime metrics (row count, scan seconds) in `scan_metrics` table | First row logged  |
| 7.5 | Survey feedback form (Google Forms) auto-sent after PDF download          | Response received |
| 7.6 | Fix any P0 bug within 24 h SLA                                            | Hotfix git tags   |
| 7.7 | Prepare KPI doc: job success %, avg runtime, PDF generation errors        | Shared PDF        |
| 7.8 | Post-mortem template & retro meeting to lock learnings                                                                        |                                 |

---

## **Done-Definition for Sprint**

* 80%+ scans succeed end-to-end on partner data (<5 min)
* CLI install to PDF under 15 min first-use
* Postgres shows ≥10 completed scans
* Landing page conversions tracked

No feature creep; any item not listed is a *post-sprint* backlog. 

## **Cross-Cutting Items**

1. **Auth / Multi-tenancy guard** — Specify JWT or magic-link auth for API before exposing endpoints.
2. **Rate-limiting** — Basic `slowapi` decorator on `/scans`.
3. **Secrets rotation** — Task to test Snowflake key rotation path.
4. **Telemetry** — Simple middleware to log request latency. 