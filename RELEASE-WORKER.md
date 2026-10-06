# Nightly widget release timer (Cloudflare) - one-time setup

GitHub's own timer started the nightly widget release hours late, or not at all (6-Oct-2026). A small Cloudflare Worker,
**davan-release**, now starts it at **9:15 pm IST**, with a backup at 9:45 pm. The release job still obeys your stop switch
(staff app → Global Switches → ⬆ Widget updates) and releases only once a night. The worker also makes **🚀 Release now**
go out within a few minutes.

It is separate from the class-alert worker (fcm-push), which stays as it is. Both run on the free Cloudflare plan.

Total time: about 10 minutes, once. It works from the phone browser.

## Part A - the GitHub key (lets the worker start the release job)

1. Open **github.com** and log in → tap your photo (top right) → **Settings**.
2. At the bottom of the menu: **Developer settings** → **Personal access tokens** → **Fine-grained tokens** → **Generate new token**.
3. Fill in:
   - **Token name:** `davan-release`
   - **Expiration:** the longest it offers (if it is 1 year, note the date - the timer stops when the key expires).
   - **Repository access:** *Only select repositories* → `harshgujjar/davan-attendance`.
   - **Permissions → Repository permissions → Actions:** *Read and write*. Leave everything else as it is.
4. **Generate token** → copy the key (starts with `github_pat_`). Keep it only for step B3 - never paste it in a chat.

## Part B - the Cloudflare worker

1. Open **dash.cloudflare.com** → **Workers & Pages** → **Create** → **Create Worker** (Hello World) →
   name it exactly **`davan-release`** → **Deploy**.
2. **Edit code** → select all and delete → paste the worker code → **Deploy**.
   The code: staff app → Global Switches → ⬆ Widget updates → **📋 Copy worker code**
   (or the file `tools/cloudflare-release-worker.js` in this repository).
3. Back to the worker → **Settings** → **Variables and Secrets** → **Add**:
   - Type **Secret**, Name **`GH_TOKEN`**, Value = the key from part A → **Deploy** (or Save).
4. **Settings** → **Trigger Events** (or Triggers) → **Add** → **Cron Triggers**:
   - `45 15 * * *` → Add  (= 9:15 pm IST; Cloudflare times are UTC)
   - `15 16 * * *` → Add  (= 9:45 pm IST backup; it does nothing if 9:15 already released)

## Check

Staff app → Global Switches → ⬆ Widget updates: the line under the buttons must say
**✅ Cloudflare release timer is on**. If it says "not set up yet", the worker name or its address is different
(it must be `https://davan-release.harshgujjar.workers.dev`), or the key is missing (step B3).

## How it works

- 9:15 pm: the worker asks GitHub to start `.github/workflows/release-widgets.yml` in **auto** mode.
- The job reads the stop switch (DB2 `davan_pub/release_ctl`): Stop tonight / Stop until resume → nothing is released.
- Otherwise it makes the newest test build public (one whole number up, e.g. w226 → w227) and writes `release-state.json`.
  A second start the same night (9:45 pm backup, GitHub's late timer) does nothing.
- 🚀 Release now in the staff app saves the request and calls the worker; the job releases only when that button was pressed.
