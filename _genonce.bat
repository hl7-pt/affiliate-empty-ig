@ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION

REM ──────────────────────────────────────────────
REM Parse --mode flag (optional, overrides auto-detection)
REM   --mode 1  force native Java
REM   --mode 2  force Docker + local jar
REM   --mode 3  force Docker bundled image
REM ──────────────────────────────────────────────
SET "force_mode="
SET "extra_args="

:parse_args
IF "%~1"=="--mode" (
    SET "force_mode=%~2"
    IF NOT "!force_mode!"=="1" IF NOT "!force_mode!"=="2" IF NOT "!force_mode!"=="3" (
        ECHO "Error: --mode must be 1 (native Java), 2 (Docker + local jar), or 3 (Docker bundled)"
        EXIT /B 1
    )
    SHIFT & SHIFT
    GOTO parse_args
)
IF NOT "%~1"=="" (
    SET "extra_args=!extra_args! %~1"
    SHIFT
    GOTO parse_args
)

REM ──────────────────────────────────────────────
REM Detect WSL distro name and username for Docker mounts
REM ──────────────────────────────────────────────
SET "wsl_distro="
SET "wsl_user="
FOR /F "tokens=*" %%i IN ('wsl -l -q 2^>nul ^| findstr /R "^[A-Za-z]"') DO (
    IF "!wsl_distro!"=="" SET "wsl_distro=%%i"
)
IF NOT "!wsl_distro!"=="" (
    FOR /F "tokens=*" %%u IN ('wsl -d !wsl_distro! whoami 2^>nul') DO SET "wsl_user=%%u"
)
IF "!wsl_distro!"=="" SET "wsl_distro=Ubuntu"
IF "!wsl_user!"=="" SET "wsl_user=root"
ECHO WSL distro: !wsl_distro!, user: !wsl_user!

REM ──────────────────────────────────────────────
REM Internet / terminology server check
REM ──────────────────────────────────────────────
ECHO Checking internet connection...
SET "tx_args="
curl -sSf tx.fhir.org >nul 2>&1
IF !ERRORLEVEL! EQU 0 (
    ECHO Online
) ELSE (
    ECHO Offline
    SET "tx_args=-tx n/a"
)

REM ──────────────────────────────────────────────
REM Locate publisher.jar (input-cache first, then parent folder)
REM ──────────────────────────────────────────────
SET "publisher_jar="
IF EXIST "input-cache\publisher.jar" (
    SET "publisher_jar=%CD%\input-cache\publisher.jar"
) ELSE IF EXIST "..\publisher.jar" (
    PUSHD ..
    SET "publisher_jar=%CD%\publisher.jar"
    POPD
)

REM ──────────────────────────────────────────────
REM Check native dependencies required to run without Docker
REM ──────────────────────────────────────────────
SET "native_deps_ok=true"
FOR %%D IN (java ruby jekyll perl) DO (
    WHERE %%D >nul 2>&1
    IF !ERRORLEVEL! NEQ 0 (
        ECHO Missing dependency: %%D
        SET "native_deps_ok=false"
    )
)

REM ──────────────────────────────────────────────
REM Run strategy
REM ──────────────────────────────────────────────

REM Determine mode: forced or auto-detected
SET "mode="
IF NOT "!force_mode!"=="" (
    SET "mode=!force_mode!"
    ECHO Mode forced: !mode!
) ELSE (
    IF NOT "!publisher_jar!"=="" (
        IF "!native_deps_ok!"=="true" (
            SET "mode=1"
        ) ELSE (
            SET "mode=2"
        )
    ) ELSE (
        SET "mode=3"
    )
)

REM Windows Docker Desktop always runs linux/amd64 — no platform flag needed

IF "!mode!"=="1" GOTO mode1
IF "!mode!"=="2" GOTO mode2
IF "!mode!"=="3" GOTO mode3

:mode1
REM ── Strategy 1: native Java (fastest) ──────
IF "!publisher_jar!"=="" (
    ECHO "Error: --mode 1 requires publisher.jar in input-cache/ or parent folder."
    EXIT /B 1
)
ECHO Running natively with Java: !publisher_jar!
SET "JAVA_TOOL_OPTIONS=!JAVA_TOOL_OPTIONS! -Dfile.encoding=UTF-8"
java -jar "!publisher_jar!" -ig . !tx_args! !extra_args!
GOTO end

:mode2
REM ── Strategy 2: Docker + local jar ─────────
REM Uses trifork image for the full environment (Sushi, Node, etc.)
REM but overrides the bundled publisher with the local jar
IF "!publisher_jar!"=="" (
    ECHO "Error: --mode 2 requires publisher.jar in input-cache/ or parent folder."
    EXIT /B 1
)
ECHO Syncing project to WSL /tmp/ig...
wsl -d !wsl_distro! -- bash -c "rm -rf /tmp/ig && mkdir -p /tmp/ig"
wsl -d !wsl_distro! -- bash -c "cp -r $(wslpath '%CD%')/. /tmp/ig/"
ECHO Using Docker with local publisher.jar: !publisher_jar!
docker run --rm ^
  -v "//wsl$/!wsl_distro!/tmp/ig":/tmp/ig ^
  -v "!publisher_jar!":/publisher.jar ^
  -v "//wsl$/!wsl_distro!/home/!wsl_user!/.fhir":/root/.fhir ^
  --entrypoint java ^
  ghcr.io/trifork/ig-publisher:latest ^
  -jar /publisher.jar -ig /tmp/ig !tx_args! !extra_args!
GOTO end

:mode3
REM ── Strategy 3: Docker bundled image ───────
ECHO Syncing project to WSL /tmp/ig...
wsl -d !wsl_distro! -- bash -c "rm -rf /tmp/ig && mkdir -p /tmp/ig"
wsl -d !wsl_distro! -- bash -c "cp -r $(wslpath '%CD%')/. /tmp/ig/"
ECHO Using ghcr.io/trifork/ig-publisher:latest
docker run --rm ^
  -v "//wsl$/!wsl_distro!/tmp/ig":/tmp/ig ^
  -v "//wsl$/!wsl_distro!/home/!wsl_user!/.fhir":/root/.fhir ^
  ghcr.io/trifork/ig-publisher:latest ^
  -ig /tmp/ig !tx_args! !extra_args!
GOTO end

:end
PAUSE
