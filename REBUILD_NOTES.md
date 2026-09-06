# Atom Rebuild Notes

Reference for setting up Atom fresh on new hardware (new M.2, new host, or disaster
recovery), plus the operational lessons learned while running/extending it. Written
after a session that added a full custom-video/picture/overlay system to the Video TV
furniture and a user-macro bar, and after discovering the whole stack's Docker storage
and live database lived on the M.2 that was about to be pulled.

## 1. What's already safe vs. what needs rebuilding

| Data | Where it lives | Survives an M.2 swap? |
|---|---|---|
| Source code, Dockerfiles, patches | This git repo (`github.com/Firecuba/nitro-docker`) | Yes — pushed |
| `assets/assets/` (bundled default assets, gamedata) | Repo directory, on the eMMC/boot drive | Yes, but gitignored — see §2 to regenerate |
| `assets/swf/` (Habbo CDN assets) | Was bind-mounted from `/mnt/nvme/atom-data/assets-swf` | **No** — fully reproducible, see §2 |
| Live MySQL database | `db/data` is a **symlink** to `/mnt/nvme/atom-data/db-data` | **No** — restore from `db/backup/` or `db/dumps/` |
| Docker's entire image/container storage | `Docker Root Dir: /mnt/nvme/docker` (~120GB) | **No** — rebuild via `docker compose build` |
| Daily DB backups | `db/backup/*.sql.gz` (tiredofit/db-backup service) | Yes — plain bind mount on the eMMC, **not** the M.2 |
| Manual DB dumps | `db/dumps/*.sql.gz` | Yes — same, on the eMMC |
| Secrets (`.env`, `.cms.env`, TLS certs, htpasswd) | Gitignored, local only | **No** — regenerate, never committed |
| User-uploaded videos/pictures | `assets/usercontent/customvideos/`, `custompictures/` | **No** — gitignored on purpose (public repo), lost if not separately copied |

**The most important discovery this session**: `docker info` will tell you where
Docker's storage root actually is (`Docker Root Dir`). On this box it was silently
pointed at `/mnt/nvme/docker` — meaning *every* running container's writable layer and
every locally-built image lived on the drive we were about to remove, not just the
database. Always check this before doing hardware maintenance:
```
docker info | grep "Docker Root Dir"
find . -maxdepth 4 -type l   # check for symlinks redirecting bind-mount sources elsewhere
```

## 2. Fresh build steps (new drive / new host)

1. **Plan storage layout first, deliberately.** Decide up front where Docker's storage
   root and the MySQL data directory should live, and configure them explicitly rather
   than letting a symlink or default choice surprise you later:
   - `/etc/docker/daemon.json`: `{"data-root": "/mnt/nvme/docker"}` (or wherever), then
     restart the Docker daemon.
   - Point `db/data` and any large asset directories directly at the intended drive via
     real bind-mount paths in `compose.yaml`, or a clearly-labeled symlink you've
     documented (unlike last time).

2. **Clone the repo and restore secrets/certs** (not in git): `.env`, `.cms.env`,
   `tls/cert.pem`, `tls/privkey.pem`, `tls/catalog_panel.htpasswd`. Regenerate fresh
   if the old ones aren't available — nothing depends on reusing the exact same
   values except existing sessions/cookies.

3. **Base assets** (from this repo's own `README.md`, steps 1 and 8):
   ```
   git clone https://git.mc8051.de/nitro/arcturus-morningstar-default-swf-pack.git assets/swf/
   git clone https://git.mc8051.de/nitro/default-assets.git assets/assets/
   unzip -o room.nitro.zip -d assets/assets/bundled/generic
   ```

4. **Up-to-date live Habbo assets** via `habbo-downloader`:
   ```
   habbo-downloader --output ./assets/swf --domain com --command badgeparts
   habbo-downloader --output ./assets/swf --domain com --command badges
   habbo-downloader --output ./assets/swf --domain com --command clothes
   habbo-downloader --output ./assets/swf --domain com --command effects
   habbo-downloader --output ./assets/swf --domain com --command furnitures
   habbo-downloader --output ./assets/swf --domain com --command gamedata
   habbo-downloader --output ./assets/swf --domain com --command gordon
   habbo-downloader --output ./assets/swf --domain com --command hotelview
   habbo-downloader --output ./assets/swf --domain com --command icons
   habbo-downloader --output ./assets/swf --domain com --command mp3
   habbo-downloader --output ./assets/swf --domain com --command pets
   habbo-downloader --output ./assets/swf --domain com --command promo
   cp -n assets/swf/dcr/hof_furni/icons/* assets/swf/dcr/hof_furni
   mv assets/swf/gordon/*PRODUCTION* assets/swf/gordon/PRODUCTION
   ./assets-build.sh
   ```

5. **Restore the database.** Drop the newest `db/backup/mysql_arcturus_db_*.sql.gz` (or
   a manual `db/dumps/*.sql.gz`) into `db/dumps/` — the official MySQL image
   auto-imports any `.sql`/`.sql.gz` file found there the *first* time it starts against
   an empty data directory. Just make sure `db/data` is genuinely empty before first
   boot, then `docker compose up db -d` and check the logs for the import.

6. **Fix upload-directory ownership.** The `cms` container's real runtime user is UID
   82 (`www-data` inside the `serversideup/php` image), not the host's default 33 —
   confirmed by `docker exec`-ing in and testing, not assumed. Any bind-mounted upload
   folder (`assets/usercontent/customvideos`, `custompictures`, `camera`, etc.) needs
   `chown 82:82` or uploads will silently fail.

7. **Build everything and bring it up:**
   ```
   docker compose build
   docker compose up -d
   ```
   Expect each custom-built image (arcturus, nitro, atomcms, catalog-panel) to take
   several minutes on first build — that's normal, not a hang.

## 3. Custom features built this session (not in the upstream project)

All server-side changes for these live in one combined patch,
`arcturus/patches/hotfix_youtube_media_and_user_macros.patch` (kept as a single file
deliberately — see §4 on patch ordering).

- **Custom video/picture upload** on the Video TV furniture (rank 7 only): upload your
  own video or picture via the popup, gated behind a required "this is my own content"
  acknowledgment checkbox. Server endpoints live in `atomcms` (`CustomVideoUploadController`,
  `CustomPictureUploadController`).
- **Live video on the furniture's actual in-room screen**, not just the popup — a
  muted, per-viewer `<video>` element decoded into a canvas at ~30fps and re-baked
  through the existing isometric-thumbnail render pipeline.
- **Picture gallery**: 6 built-in generated presets (`assets/gallery/pictures/`) plus
  upload-your-own, sourced the same way as custom video.
- **Screen overlays/frames**: 5 built-in generated overlays (`assets/gallery/overlays/`,
  transparent PNGs) composited on top of whatever's playing, with an on/off toggle and
  a manual "Force Refresh" override.
- **Minimize/dock side-tab** for the Video TV widget: collapses to a small label tab
  docked to a screen edge (left/right, flippable), click to restore.
- **Ambient room audio**: an opt-in toggle so an uploaded video's audio keeps playing
  (for you, and independently for anyone else who opts in) even after closing the
  popup — requires an explicit click per browser autoplay-with-sound rules.
- **User macro bar**: click another player's avatar to throw a small cosmetic effect
  at them, have them walk over to you, or start a whisper. No rank gate. Built on top
  of emulator mechanisms that already existed (`Room.giveEffect`,
  `RoomUnitWalkToRoomUnit`) rather than new game logic.

## 4. Lessons learned (the expensive-to-relearn kind)

- **A `docker compose up -d <service>` can silently recreate services you didn't name**,
  if they depend on another service whose image was just rebuilt (`depends_on`
  cascades). Confirmed the hard way when deploying `cms` also recreated `arcturus`
  (disconnecting every player) with no prompt. Check `docker compose up -d --no-deps
  <service>` when you specifically want to touch only one service.

- **Custom fixed-position UI must render through the app's real window portal**, not
  inline in the normal component tree. This client mounts every game window via
  `createPortal` into `document.getElementById("draggable-windows-container")`
  (`DraggableWindow.tsx`). A plain `position: fixed` div rendered elsewhere can be
  visually correct and completely unclickable, because it inherits a different
  stacking/positioning context from whatever ancestor it happens to sit under. Cost us
  two failed attempts before we mounted through the portal like everything else does.

- **Clicks inside a cross-origin iframe never bubble to the parent DOM.** A YouTube
  iframe embedded in a "minimized preview" made that preview permanently unclickable
  for restoring — no amount of z-index or event-handler tweaking fixes this, since the
  event never reaches the parent at all. Don't embed live third-party iframes in
  anything that needs a click-through/restore interaction; use a plain label instead.

- **Python patch-script string anchors can silently match as a substring of a more-
  indented line elsewhere in the file.** `content.count("    this._x = null;\n")` can
  return 2 instead of 1 if a differently-indented copy of that exact tail exists
  elsewhere (e.g. 6-space-indented text contains the 4-space string as a suffix).
  Anchor on a full line plus a neighboring line for uniqueness, not a short indented
  fragment alone.

- **Arcturus's Dockerfile applies patches via `find | xargs`, in non-deterministic
  order.** Any feature that needs more than one patch, where a later patch depends on
  an earlier one's changes, will intermittently fail to apply. Keep multi-part
  features as one combined patch (`git diff <pristine-commit>` from a scratch clone),
  not several smaller ones with an implicit dependency order.

- **Browsers block unmuted autoplay without a genuine prior user gesture** (muted
  autoplay is always allowed). Any "ambient/automatic" audio feature has to be built
  around an explicit click to enable it — there's no way to make it silently start
  playing sound for a bystander who never interacted with the page.

- **This stack has two independent nginx body-size limits**, not one: the `tls-proxy`
  container (TLS termination, in front of everything) and the `cms` container's own
  internal nginx. Raising the limit in only one silently 413s uploads before they ever
  reach the other layer or Laravel — and produces no application-level log entry,
  since it's rejected before the request is ever routed there.

- **`.cms.env` becomes Laravel's `.env` file (PHP-only) when bind-mounted** — it is
  invisible to the `cms` container's own nginx entrypoint templating (`envsubst`).
  Real container environment variables need an explicit `environment:` block in
  `compose.yaml`, not just a value in `.cms.env`.

- **A bind-mounted upload directory's writable UID must be verified, not assumed.**
  The host default (`www-data` = UID 33 on Debian) did not match this image's actual
  runtime user (UID 82) — confirmed via `docker exec ... id www-data` and a real
  `touch`/`stat` test inside the container, not guessed from convention.

- **Check `docker info | grep "Docker Root Dir"` and scan for symlinks
  (`find . -type l`) before any hardware maintenance.** The single biggest risk this
  session wasn't the database (which had an existing daily-backup safety net we'd
  forgotten about) — it was that Docker's *entire* storage root, invisible unless you
  go looking, lived on the drive about to be removed.

## 5. Things worth doing differently next time

- Configure Docker's `data-root` explicitly in `daemon.json` from day one, with a
  comment nearby explaining why, instead of letting it default/drift onto whichever
  drive happens to be biggest.
- Keep `db/backup/` (or an equivalent) somewhere *not* on the same drive as the live
  database, which it already was, by luck, this time — verify that stays true after
  any storage reshuffle.
- Consider `.gitignore`-driven review as a standing step before any `git push` to a
  public repo, not just before a first push: this session it caught a credential
  hash file, three nested third-party git repos, and 18MB of personal upload content
  that had no business going into public history.
