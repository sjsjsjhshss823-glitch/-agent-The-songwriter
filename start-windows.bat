@echo off
setlocal
cd /d "%~dp0"
where docker >nul 2>nul
if errorlevel 1 (
  echo Docker Desktop is required. Install and start it first.
  exit /b 1
)
if not exist .env copy .env.example .env
if not exist data mkdir data
if not exist media mkdir media
if not exist secrets mkdir secrets
if not exist secrets\client_secret.json (
  echo Missing secrets\client_secret.json. Add your Google OAuth client JSON locally. Never commit it.
  exit /b 2
)
echo Starting SongFlow API. ACE-Step must be running separately on the host at port 8001.
docker compose up --build -d
echo Open http://localhost:8000/docs and complete YouTube OAuth before queueing a private test song.
