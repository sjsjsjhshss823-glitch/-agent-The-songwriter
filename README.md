# SongFlow Free — local AI songs to YouTube

> **Phone-first, free-only path:** open [`phone-free.html`](./phone-free.html) for a Hebrew mobile helper, or read [`FREE_PHONE_GUIDE.md`](./FREE_PHONE_GUIDE.md). It builds a music prompt and links to the official public ACE-Step demo. This path can help create a song manually, but does **not** run the background agent or upload to YouTube automatically. Public demo availability and free quotas are not guaranteed.

**No paid service was created.** Do not deploy the Render blueprint below if you require a strictly free setup.

A separate local-first alternative to `song-agent/`. It does not replace or modify SafeGuard. It uses the open-source ACE-Step 1.5 music model through its local HTTP API, creates a simple MP4 cover video, and uploads through your own YouTube OAuth authorization.

## Important: what must exist before it can run

GitHub stores the code; it does not run this agent continuously. **This version needs a computer or server running ACE-Step 1.5**, plus Docker, internet access, and a Google OAuth client file. It cannot start music generation from an Android phone or from GitHub alone. Do not put OAuth files or passwords in the repository.

## Optional paid cloud deployment (Render) — NOT part of the free-only path

The repository includes `render.yaml` for creating the API service from the Render dashboard. This is **not a one-click complete music generator**: Render hosts the API/queue, but the ACE-Step music model must be running separately on a reachable GPU host with an HTTPS API URL. Do not use a private `localhost` URL for `ACE_STEP_API_URL`.

1. Open [Render Blueprints](https://dashboard.render.com/blueprints) in your phone browser and connect your GitHub account if asked.
2. Create a Blueprint from this repository and select `render.yaml`. The service configuration uses a **paid** plan and a persistent disk so the queue, generated media, and YouTube OAuth token survive restarts. Review the current price in Render before creating it; this configuration does not deploy or charge anything by itself.
3. During setup, provide `ACE_STEP_API_URL`: the HTTPS base URL of your separately hosted ACE-Step API. If that server uses an API key, add `ACE_STEP_API_KEY` in the Render service's Environment settings.
4. Finish the first deployment and copy the service URL shown by Render, for example `https://your-service.onrender.com`.
5. In Google Cloud Console, configure a **Web application** OAuth client for YouTube Data API v3 and add this exact authorized redirect URI: `https://your-service.onrender.com/oauth/callback` (replace the example hostname with the actual Render URL). Put the complete OAuth client JSON into the Render environment variable `YOUTUBE_CLIENT_SECRETS_JSON`; never put it in GitHub. If you entered it before the final URL was known, update the value and redeploy.
6. In Render's Environment settings, copy the generated `APP_TOKEN` somewhere safe. Use it as the `X-App-Token` header when calling protected job endpoints. Do not share it publicly.
7. Open `https://your-service.onrender.com/health` to check service status. Then open `/oauth/start` and complete Google authorization. The initial upload visibility is private. Check the health response for `ace_step_reachable: true` before queuing one test job.
8. Keep `YOUTUBE_PRIVACY_STATUS=private` until you review the first upload in YouTube Studio.

**Important limits:** Render does not provide the ACE-Step GPU model as part of this blueprint. A separate GPU host may cost money. The API service alone cannot generate music if that model endpoint is unavailable. This setup has not been deployed or end-to-end tested yet.

## Quick start (computer with Docker)

1. Install and start Docker Desktop/Engine.
2. Install ACE-Step 1.5 using its official instructions and start its API on the host at `http://localhost:8001`. Confirm `http://localhost:8001/health` responds. Model downloads and generation need suitable hardware; GPU requirements depend on the selected model.
3. In Google Cloud Console, enable **YouTube Data API v3**, configure OAuth consent, and create an OAuth client. Download its JSON and save it locally as `secrets/client_secret.json`. For a Web client, configure redirect URI `http://localhost:8000/oauth/callback`; follow Google's current guidance for your OAuth client type.
4. In `./`, copy `.env.example` to `.env`. Keep `YOUTUBE_PRIVACY_STATUS=private` for the first test. Change the sample `APP_TOKEN` to a long random secret.
5. Run `bash start-linux-macos.sh` on macOS/Linux, or run `start-windows.bat` on Windows after reviewing `.env`. This builds and starts the API container. ACE-Step must be running separately on the same host.
6. Open [http://localhost:8000/docs](http://localhost:8000/docs), open `GET /oauth/start`, and complete Google authorization.
7. Check `GET /health`. Queue one private test song using `POST /jobs/fill-today` with JSON body `{"count":1,"language":"English"}`. If `APP_TOKEN` is set, include the `X-App-Token` header.
8. Check `GET /jobs` until the job is published. Review the private video in YouTube Studio before changing `YOUTUBE_PRIVACY_STATUS=public`.

To stop the service, run `docker compose down` from this folder. Data, tokens, and media remain in local `data/` and `media/` directories.

## Cost and limits

- The agent makes no paid music-generation API calls; the model runs on your own computer/server. Hardware, electricity, internet data, and any hosted GPU may cost money.
- Check the official project and exact model-weight license before commercial use: [ACE-Step](https://github.com/ace-step/ACE-Step) and [ACE-Step 1.5](https://github.com/ace-step/ACE-Step-1.5).
- YouTube uploads require a Google Cloud project, OAuth consent, YouTube Data API access, and available quota. API project restrictions and account standing may prevent uploads.
- The agent caps the daily queue at 50 jobs in UTC. This is a maximum target, not a guarantee of 50 completed or published songs.
- Repetitive or mass-produced content may not qualify for YouTube monetization. Make distinct original work and do not imitate named artists or copyrighted songs.
- Upload visibility defaults to **private** for testing. The video is a static cover image with audio, not moving AI footage.

## API

- `GET /health` — API status, ACE-Step reachability, queue status.
- `GET /oauth/start` and `GET /oauth/callback` — YouTube OAuth setup.
- `POST /jobs/fill-today` — queue jobs up to the daily target.
- `GET /jobs` — inspect queue and publication status.
- `POST /jobs/{job_id}/retry` — retry a failed job.

## Security

- Keep `.env`, OAuth client JSON, token JSON, database, and generated media outside Git.
- The Compose configuration binds the API to `127.0.0.1` only. Do not expose it publicly without HTTPS and strong authentication.
- Never commit API keys, Google OAuth secrets, or token files.
