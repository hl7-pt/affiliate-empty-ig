@ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION

ECHO Checking internet connection...
PING tx.fhir.org -4 -n 1 -w 1000 | FINDSTR TTL >nul
IF %ERRORLEVEL% EQU 0 (
    ECHO We're online
    SET "txoption="
) ELSE (
    ECHO We're offline...
    SET "txoption=-tx n/a"
)

REM Run IG Publisher using Docker
docker run --rm -v "%CD%":/tmp/ig ghcr.io/trifork/ig-publisher:latest -ig /tmp/ig %txoption% %*

PAUSE
