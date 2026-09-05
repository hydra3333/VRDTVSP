"""
VRDTVSP_Run_QSF_with_v5_or_v6.py

Python replacement for the legacy VBScript:
    VRDTVSP_Run_QSF_with_v5_or_v6.vbs

PURPOSE
=======
Run ONE VideoReDo QuickStreamFix (QSF) attempt using an explicitly selected
VideoReDo version and explicitly supplied output/QSF profile, validate that
VideoReDo's completion information belongs to THIS requested output, and
create an ASCII .BAT/.CMD file containing SET commands for the QSF result
values.

The outer batch file remains responsible for orchestration, including:
    * trying VideoReDo v5 first;
    * detecting any v5 failure or hard timeout;
    * falling back to VideoReDo v6;
    * applying a much longer v6 timeout;
    * providing a true process-level watchdog capable of killing this Python
      process if a VideoReDo COM call itself hangs and never returns.

That separation is intentional.  An in-process Python timer cannot interrupt a
COM method which is itself hung and has not returned control to Python.  The
outer batch watchdog therefore remains an essential part of the design.

COMMAND-LINE CONTRACT
=====================
The positional interface intentionally mirrors the existing VBS worker.

Mandatory positional arguments:
    0   VideoReDo version: 5 or 6
    1   input video file
    2   output QSF video file
    3   exact VideoReDo QSF/output profile name
    4   output .BAT/.CMD file containing SET commands
    5   prefix for variables written to that .BAT/.CMD file
    6   fallback ActualVideoBitrate in bits/second

Optional positional argument:
    7   internal/cooperative QSF timeout in minutes
        default: 300

Example:
    python VRDTVSP_Run_QSF_with_v5_or_v6.py ^
        5 ^
        "G:\\TEMP\\input.ts" ^
        "G:\\TEMP\\output.QSF.MP4" ^
        "VRDTVS-for-QSF-H264_VRD5" ^
        "G:\\TEMP\\qsf_variables.bat" ^
        "QSFinfo_" ^
        5000000 ^
        15

EXIT CODES
==========
    0   Success.

    5   Command-line/configuration/precondition error.
        Examples include invalid arguments, unsafe path identities, missing
        input, invalid requested profile, invalid timeout, or inability to
        prepare stale output files after successful preflight validation.

    17  VideoReDo/QSF operational failure.
        Examples include COM failure, FileOpen/FileSaveAs failure, polling
        failure, internal timeout, unusable completion XML, wrong completion
        outputFile, missing/empty final QSF output, or failure to create the
        result command file.

COM / THREADING PRESERVATION POLICY
===================================
1. This application is intentionally single-threaded.

2. All VideoReDo COM objects are created, accessed and released exclusively
   on the process main thread.

3. The process main thread must operate in a Windows COM Single-Threaded
   Apartment (STA / Main STA).

4. Standard, GIL-enabled CPython is required.

5. Free-threaded / no-GIL-capable CPython builds are deliberately unsupported
   by this version, even if the GIL could be enabled at runtime.  Reconsidering
   that rule requires suitable pywin32 support, a deliberate COM/threading
   review, and complete regression testing.

6. Do NOT introduce threading.Thread, ThreadPoolExecutor, asyncio.to_thread(),
   run_in_executor(), or any other cross-thread access to VideoReDo COM
   objects without a new COM-threading design review and regression proof.

7. Intended lifetime:
       one process
           -> one Python main thread
               -> one Windows STA
                   -> one VideoReDo automation instance
                       -> one QSF attempt
                           -> process exits

8. COM invocation syntax must not be inferred mechanically from VBScript.
   Actual v5/v6 testing showed that some members written Foo() in VBScript are
   exposed by pywin32 as property values rather than callables.

VALIDATED MIGRATION BASELINE
============================
Initial migration proof environment:
    * CPython 3.14.7 x64, standard/GIL build
    * pywin32 312
    * VideoReDo TVSuite v5
    * VideoReDo TVSuite v6
    * Windows COM Main STA

Observed pywin32 exposure:
    ProfilesGetCount             property/value
    ProfilesGetProfileName(i)    callable indexed member
    ProfilesGetProfileIsAdScan   callable in v6, absent in v5
    FileOpen                     callable
    FileSaveAs                   callable
    FileClose                    callable
    OutputGetState               property/value
    OutputGetPercentComplete     property/value
    OutputGetCompletedInfo       property/value
    ProgramExit                  callable

Observed output state behaviour:
    v5: idle 2 -> processing 1 -> completed 0
    v6: idle 0 -> processing 1 -> completed 0

OutputGetState == 0 AFTER FileSaveAs is the completion authority.
OutputGetPercentComplete is diagnostic only.  Testing showed that v5 could
finish with state 0 while percent still reported 99.9981, whereas v6 could
finish with state 0 after percent had reset to 0.

COMPLETION-INFO SEQUENCING INVARIANT
====================================
Preserve this exact ordering:

    QSF completes (OutputGetState == 0)
        ->
    obtain and validate OutputGetCompletedInfo
        ->
    prove outputFile identifies THIS QSF output
        ->
    FileClose
        ->
    ProgramExit

OutputGetCompletedInfo is intentionally obtained BEFORE FileClose because the
legacy workflow established that this ordering matters with VideoReDo.

CHG-11: PROVENANCE. Two distinct facts are combined above and must not be
confused by a future maintainer:

  INHERITED from the legacy VBS workflow:
      the raw OutputGetCompletedInfo call must occur after QSF completion and
      before FileClose.

  ADDED by this Python worker, NOT inherited:
      parsing that XML, and proving its outputFile identifies THIS output,
      also happen before FileClose. The VBS fetched the raw string, then
      called FileClose and ProgramExit, and only then parsed and checked it
      (vbs lines 511-593).

That validation-before-close step is a deliberate strengthening. It is sound,
but it is this program's design decision and carries no VBS provenance.

MEASURED COMPLETION-AUTHORITY EVIDENCE (probe runs A/B/C)
========================================================
Three instrumented runs on the validated target machine measured the following:

  * OutputGetCompletedInfo was EMPTY on every fresh DispatchEx instance tested,
    including a run that deliberately reused the immediately preceding run's
    exact output path.

  * OutputGetState read 1 within 0.058-0.065 ms of FileSaveAs returning on all
    three runs, covering both installed VideoReDo versions. This is strong
    empirical evidence that these validated installations establish processing
    state before FileSaveAs returns; it is an engineering inference, not an
    undocumented API guarantee.

  * OutputGetPercentComplete read 0, reached ~99.9939% within about four seconds
    of a 47-second job, held there, then read 0.0 at completion. It is neither a
    reliable whole-job progress indicator nor a completion signal.

LOAD-BEARING ONE-QSF-PER-PROCESS PRECONDITION
=============================================
The reasoning above relies on this worker continuing to perform exactly ONE
FileSaveAs/QSF operation per fresh DispatchEx process. Under that architecture,
the measurements provide strong empirical support for the existing completion
logic and for leaving the withdrawn CHG-07/CHG-09 machinery out.

If a future maintainer changes this worker to perform a second FileSaveAs in the
same process/VideoReDo instance, these measurements no longer establish that a
prior completion record cannot be present. The completion-authority design MUST
then be re-reviewed and re-measured before that change is accepted.

XML POLICY
==========
VideoReDo does not always provide every optional output-information field.
Missing optional data is therefore legitimate.

Required:
    * well-formed XML
    * root element VRDOutputInfo
    * non-empty outputFile attribute
    * outputFile must identify THIS requested QSF output

Optional:
    * OutputType
    * OutputDurationSecs
    * OutputDuration
    * OutputSizeMB
    * OutputSceneCount
    * VideoOutputFrameCount
    * AudioOutputFrameCount
    * ActualVideoBitrate

Missing optional fields are reported and omitted from the generated command
file, except ActualVideoBitrate, which always receives either a defensibly
interpreted VideoReDo value or the caller-supplied fallback bitrate.

OUTPUT COMMAND-FILE ENCODING POLICY
===================================
The generated .BAT/.CMD file is deliberately strict ASCII for now.  This keeps
the conservative behaviour of the existing workflow, which contains a
historical warning about downstream Unicode problems.  No unrepresentable
character is silently substituted.

The command file is written to a temporary sibling file, flushed, fsynced,
closed, then atomically installed with os.replace().

Each generated command line suppresses only ITS OWN echo using '@'.  The file
does not inspect or change the caller's global ECHO mode.

DEBUGGING POLICY
================
DEBUG_PRINT below is the single global detailed-debug switch.

When True, debug_print() writes timestamped diagnostics to STDERR and flushes
immediately.  The existing batch redirects stdout and stderr together to its
log, so these diagnostics naturally appear there.

Performance is deliberately secondary to observability for this preservation
application.
"""

from __future__ import annotations

# ============================================================================
# Standard-library imports only.
#
# pywin32 is imported later, AFTER sys.coinit_flags has established the COM
# apartment policy required for the main thread.
# ============================================================================

import ctypes
from dataclasses import dataclass
from datetime import datetime
from decimal import Decimal, InvalidOperation, ROUND_HALF_EVEN
import gc
import importlib.metadata
import os
from pathlib import Path
import platform
import re
import struct
import sys
import sysconfig
import tempfile
import threading
import time
import traceback
from typing import Any
import xml.etree.ElementTree as ET

# ============================================================================
# Global program constants
# ============================================================================

SCRIPT_NAME = "VRDTVSP_Run_QSF_with_v5_or_v6.py"
SCRIPT_VERSION = "1.0.0"

# Single global debug switch.
#
# True is intentional for the first production candidate.  
# After the Python worker has been validated against the established VBS
# behaviour over a representative corpus, changing this to False will quiet
# detailed debug # messages without changing any functional control flow.
DEBUG_PRINT = True

MINIMUM_PYTHON = (3, 14)
MINIMUM_PYWIN32_MAJOR = 312

# Windows COM COINIT_APARTMENTTHREADED.
# This literal must exist BEFORE pythoncom is imported (pywin32 imports).
COINIT_APARTMENTTHREADED_VALUE = 0x2

VIDEOREDO_PROGIDS = {
    5: "VideoReDo5.VideoReDoSilent",
    6: "VideoReDo6.VideoReDoSilent",
}

# Existing VBS polls every 2 seconds.  Preserve that cadence.
QSF_POLL_INTERVAL_SECONDS = 2.0

# Human-oriented stdout status cadence.  DEBUG_PRINT still records every poll.
PROGRESS_STATUS_INTERVAL_SECONDS = 120.0

# The VBS had repeated 100 ms completion-info retries.  Preserve the workaround
# while making it stronger: retry empty, malformed, stale, and transiently
# failing completion info until this bounded deadline.
COMPLETED_INFO_RETRY_DELAY_SECONDS = 0.10
COMPLETED_INFO_MAX_WAIT_SECONDS = 5.0

DEFAULT_QSF_TIMEOUT_MINUTES = 300

EXIT_SUCCESS = 0
EXIT_CONFIGURATION_ERROR = 5
EXIT_OPERATION_ERROR = 17

# ---------------------------------------------------------------------------
# ActualVideoBitrate interpretation constants.
#
# VideoReDo was observed returning decimal Mbps values such as 2.325295.
# Historical XML embedded in the old VBS also showed integer-like 2552071,
# which is plausible as already-bps.
#
# User-confirmed scope: no 4K; legitimate video bitrates can range from very
# low values through roughly 26 Mbps for 1080p.
#
# Policy:
#   0 < value <= 30              -> interpret as Mbps
#   50,000 <= value <= 30,000,000 -> interpret as already-bps
#   everything else              -> ambiguous; use caller fallback
#
# The deliberate 30..50,000 gap prevents guessing units for suspicious data.
# ---------------------------------------------------------------------------
VRD_BITRATE_MAX_EXPECTED_MBPS = Decimal("30")
VRD_BITRATE_MIN_PLAUSIBLE_ALREADY_BPS = Decimal("50000")
VRD_BITRATE_MAX_EXPECTED_BPS = Decimal("30000000")

# Variable names produced by this worker must be conventional cmd.exe names.
CMD_VARIABLE_PREFIX_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")

# ---------------------------------------------------------------------------
# CHG-10: units declared by VideoReDo in the completion XML.
#
# Measured on both installed versions, the ActualVideoBitrate element carries
# its own unit declaration:
#
#   <ActualVideoBitrate desc="Actual Video Bitrate:" desc_format="%24s"
#                       val_type="float" val_format="%0.2f Mbps">1.931474</...>
#
# The unit is therefore stated by VideoReDo rather than something that has to
# be inferred from the magnitude of the number.
#
# Only val_format is trusted as a unit declaration because it is the attribute
# actually observed to carry the unit on both installed VideoReDo versions.
# Generic descriptive attributes are deliberately NOT treated as authoritative
# unit metadata. If val_format has no recognized unit, the existing magnitude
# heuristic remains available as the compatibility fallback.
#
# The regular expression requires a non-letter boundary on BOTH sides of the
# token, so malformed text such as "MbpsSomething" cannot be accepted as a
# declaration.
# ---------------------------------------------------------------------------
VRD_BITRATE_UNIT_ATTRIBUTE = "val_format"
VRD_DECLARED_BITRATE_MULTIPLIERS: dict[str, int] = {
    "gbps": 1_000_000_000,
    "mbps": 1_000_000,
    "kbps": 1_000,
    "bps": 1,
}
VRD_DECLARED_BITRATE_UNIT_RE = re.compile(
    r"(?<![A-Za-z])(Gbps|Mbps|kbps|bps)(?![A-Za-z])",
    re.IGNORECASE,
)

# Rejected inside values written as:
#     @SET "NAME=value"
# in a caller known to use delayed expansion.
#
#   %  expands percent variables
#   !  expands delayed-expansion variables
#   "  breaks the SET quoting discipline
#   CR/LF/NUL can corrupt/inject commands
#   ^  is cmd.exe's escape character; reject conservatively
UNSAFE_CMD_VALUE_CHARACTERS = frozenset(
    {"%", "!", '"', "\r", "\n", "\x00", "^"}
)

# XML nodes which are useful but legitimately may be absent.
OPTIONAL_XML_FIELDS = (
    "OutputType",
    "OutputDurationSecs",
    "OutputDuration",
    "OutputSizeMB",
    "OutputSceneCount",
    "VideoOutputFrameCount",
    "AudioOutputFrameCount",
)

# Windows COM apartment type/qualifier constants.
APTTYPE_STA = 0
APTTYPE_MTA = 1
APTTYPE_NA = 2
APTTYPE_MAINSTA = 3

APTTYPEQUALIFIER_NONE = 0
APTTYPEQUALIFIER_IMPLICIT_MTA = 1
APTTYPEQUALIFIER_NA_ON_MTA = 2
APTTYPEQUALIFIER_NA_ON_STA = 3
APTTYPEQUALIFIER_NA_ON_IMPLICIT_MTA = 4
APTTYPEQUALIFIER_NA_ON_MAINSTA = 5
APTTYPEQUALIFIER_APPLICATION_STA = 6
APTTYPEQUALIFIER_RESERVED_1 = 7

# ============================================================================
# Module runtime bindings/state
#
# Declarations only. Importing this module does NOT initialize COM, configure
# diagnostic streams, or run application startup. bootstrap_com_runtime() is
# the single owner of process/runtime COM initialization.
# ============================================================================

# Deferred pywin32 module bindings, committed only after bootstrap validation.
pythoncom: Any = None
win32com_client: Any = None

# Runtime facts discovered and committed by bootstrap_com_runtime().
PYTHON_BITS: int | None = None
STARTUP_NATIVE_THREAD_ID: int | None = None
_IS_GIL_ENABLED: Any = None
PYWIN32_VERSION: str | None = None
_COM_RUNTIME_BOOTSTRAPPED = False

# Native Windows function caches populated lazily by their helper functions.
_CACHED_GET_CURRENT_THREAD_ID: Any = None
_CACHED_GET_APARTMENT_TYPE: Any = None

# CHG-05: set once the first time OutputGetPercentComplete proves unreadable,
# so a permanently broken diagnostic member cannot flood the caller's log.
# This is process/run state because the worker performs exactly one QSF per
# process. If that architecture changes, this must become per-run state.
PERCENT_READ_WARNING_EMITTED = False

# ============================================================================
# Explicit failure classes -> stable exit-code model
# ============================================================================

class ConfigurationError(Exception):
    """Command-line/configuration/precondition failure -> exit code 5."""

class OperationError(Exception):
    """VideoReDo/QSF operational failure -> exit code 17."""

# ============================================================================
# Immutable run configuration
# ============================================================================

@dataclass(frozen=True)
class RunConfig:
    vrd_version: int
    input_path: Path
    output_path: Path
    qsf_profile_name: str
    output_cmd_path: Path
    variable_prefix: str
    fallback_bitrate_bps: int
    timeout_minutes: int

    @property
    def timeout_seconds(self) -> float:
        return float(self.timeout_minutes) * 60.0

    @property
    def progid(self) -> str:
        return VIDEOREDO_PROGIDS[self.vrd_version]

# ============================================================================
# Immediate-output logging helpers
# ============================================================================

def _now_string() -> str:
    """Return local timezone-aware time for diagnostic records."""
    return datetime.now().astimezone().isoformat(
        sep=" ",
        timespec="milliseconds",
    )

def status_print(*parts: object) -> None:
    """
    Normal status output to stdout, always flushed.

    Immediate flush matters because the outer watchdog may terminate a hung
    worker and the log should contain the most recent completed step.
    """
    print(*parts, file=sys.stdout, flush=True)

def debug_print(*parts: object) -> None:
    """
    Detailed timestamped debug output to stderr, controlled only by
    DEBUG_PRINT.
    """
    if not DEBUG_PRINT:
        return
    try:
        native_tid: object = threading.get_native_id()
    except Exception:
        native_tid = "?"
    print(
        f"[DEBUG {_now_string()} tid={native_tid}]",
        *parts,
        file=sys.stderr,
        flush=True,
    )

def warning_print(*parts: object) -> None:
    """Warning output to stderr, always flushed."""
    print(
        f"[WARNING {_now_string()}]",
        *parts,
        file=sys.stderr,
        flush=True,
    )

def error_print(*parts: object) -> None:
    """Error output to stderr, always flushed."""
    print(
        f"[ERROR {_now_string()}]",
        *parts,
        file=sys.stderr,
        flush=True,
    )

# ----------------------------------------------------------------------------
# diagnostic-stream encoding safety.
#
# PROBLEM ADDRESSED:
#   When this worker's output is redirected into the caller's log (which it
#   always is), CPython selects the process ANSI code page - typically cp1252 -
#   for sys.stdout, with the STRICT error handler. Any character in a source
#   filename or profile name that cp1252 cannot represent then raises
#   UnicodeEncodeError INSIDE status_print(), aborting the run before any QSF
#   work is attempted and logging a Unicode failure instead of the real
#   situation.
#
#   Measured: cp1252 accepts Western European accents and typographic
#   punctuation, but raises on Greek, Cyrillic, Arabic, CJK, Polish and Turkish
#   characters. For an Australian OTA workflow that includes SBS, non-Latin
#   programme titles are reachable in normal use.
#
#   SCOPE CORRECTION: this affects stdout only. CPython already defaults
#   sys.stderr to 'backslashreplace', so debug_print(), warning_print() and
#   error_print() were never exposed. Both streams are set explicitly anyway so
#   the behaviour is deterministic rather than dependent on interpreter
#   defaults, which change: PEP 686 makes UTF-8 mode the default from CPython
#   3.15, which would otherwise mask this on 3.15 but not on 3.14.
#
# APPROACH:
#   Keep each stream's existing encoding, so the worker's lines stay consistent
#   with the cmd.exe-generated lines around them in the shared log, but replace
#   the strict error handler with 'backslashreplace'. Unrepresentable
#   characters are then recorded visibly as backslash escapes instead of
#   terminating the worker.
#
#   This affects DIAGNOSTIC OUTPUT ONLY. The generated .BAT command file
#   remains strict US-ASCII and is unchanged by this.
# ----------------------------------------------------------------------------

def configure_diagnostic_stream_errors() -> None:
    """Use visible backslash escapes instead of aborting diagnostic output."""
    for stream_name in ("stdout", "stderr"):
        stream = getattr(sys, stream_name, None)
        reconfigure = getattr(stream, "reconfigure", None)
        if reconfigure is None:
            continue
        try:
            reconfigure(errors="backslashreplace")
        except Exception as exc:  # pragma: no cover - defensive only
            print(
                f"[WARNING] Could not reconfigure sys.{stream_name} error "
                f"handler: {type(exc).__name__}: {exc}",
                file=sys.stderr,
                flush=True,
            )

# ============================================================================
# Native Windows-thread helper used before pywin32 imports
# ============================================================================

# ----------------------------------------------------------------------------
# Cache the kernel32/ole32 function prototypes.
#
# PROBLEM ADDRESSED:
#   get_current_windows_thread_id() and get_windows_com_apartment() each
#   performed a fresh ctypes.WinDLL() load and re-declared the argtypes/restype
#   on EVERY call. Both are reached from assert_main_sta_context(), which
#   sta_sleep() invokes on every 50 ms inner iteration - roughly 20 times per
#   second for the entire duration of a QSF that may run for hours.
#
#   Repeatedly constructing DLL wrappers and resolving/redeclaring the same
#   function signatures is pointless work on the hot path of a long-running
#   preservation tool. No stronger claim about ctypes' library-lifetime
#   implementation is required for this change.
#
#   NOTE: this change is hygiene only. The frequency of the invariant CHECKS is
#   deliberately left untouched - strict runtime policing is a design value of
#   this project, and after this change the residual cost of those checks is
#   negligible against QSF durations.
#
# APPROACH:
#   Resolve each library and prototype exactly once, lazily, and reuse it.
#   Lazy rather than import-time resolution keeps ole32 loading out of the
#   pre-pywin32 startup sequence, so COM apartment policy is still established
#   solely by sys.coinit_flags before pythoncom is imported.
# ----------------------------------------------------------------------------

def get_current_windows_thread_id() -> int:
    """
    Return Windows' native ID for the current thread.

    We compare this with Python's native thread ID at startup and repeatedly
    during COM activity to prove that VideoReDo never migrates to another
    Python/OS thread.
    """
    global _CACHED_GET_CURRENT_THREAD_ID
    if _CACHED_GET_CURRENT_THREAD_ID is None:
        kernel32 = ctypes.WinDLL("kernel32", use_last_error=True)
        func = kernel32.GetCurrentThreadId
        func.argtypes = ()
        func.restype = ctypes.c_ulong
        _CACHED_GET_CURRENT_THREAD_ID = func
    return int(_CACHED_GET_CURRENT_THREAD_ID())

# ============================================================================
# Runtime self-policing BEFORE importing pythoncom / win32com
# ============================================================================

def perform_pre_pywin32_runtime_checks() -> tuple[int, int, Any]:
    """
    Validate all invariants which must hold before pywin32 initializes COM.

    Returns:
        python bitness,
        startup native thread ID,
        sys._is_gil_enabled callable
    """
    debug_print("Starting pre-pywin32 runtime checks.")
    if sys.platform != "win32":
        raise ConfigurationError(
            f"Windows is required; sys.platform={sys.platform!r}"
        )
    implementation = platform.python_implementation()
    if implementation != "CPython":
        raise ConfigurationError(
            f"Standard CPython is required; found {implementation!r}"
        )
    if sys.version_info < MINIMUM_PYTHON:
        raise ConfigurationError(
            f"Python {MINIMUM_PYTHON[0]}.{MINIMUM_PYTHON[1]} or later "
            f"is required; found {sys.version.split()[0]}"
        )
    python_bits = struct.calcsize("P") * 8
    if python_bits != 64:
        raise ConfigurationError(
            f"64-bit Python is required; found {python_bits}-bit Python"
        )
    py_gil_disabled_build = sysconfig.get_config_var("Py_GIL_DISABLED")
    debug_print("Py_GIL_DISABLED build value =", repr(py_gil_disabled_build))

    # Current preservation policy deliberately rejects the optional
    # free-threaded build even if someone subsequently enables its GIL.
    if py_gil_disabled_build == 1:
        raise ConfigurationError(
            "Free-threaded/no-GIL-capable CPython build detected "
            "(Py_GIL_DISABLED=1). Use the standard GIL-enabled build."
        )
    is_gil_enabled = getattr(sys, "_is_gil_enabled", None)
    if is_gil_enabled is None:
        raise ConfigurationError(
            "sys._is_gil_enabled() is unavailable, so the required runtime "
            "GIL state cannot be verified. Revalidation is required."
        )
    if not is_gil_enabled():
        raise ConfigurationError(
            "The Global Interpreter Lock (GIL) is disabled at runtime."
        )
    if threading.current_thread() is not threading.main_thread():
        raise ConfigurationError(
            "Program startup is not executing on Python's main thread."
        )
    active_threads = threading.enumerate()
    if len(active_threads) != 1:
        raise ConfigurationError(
            "Unexpected additional Python thread(s) already exist at "
            f"startup: {[t.name for t in active_threads]!r}"
        )
    startup_native_thread_id = threading.get_native_id()
    startup_windows_thread_id = get_current_windows_thread_id()
    if startup_native_thread_id != startup_windows_thread_id:
        raise ConfigurationError(
            "Python native thread ID and Windows GetCurrentThreadId() "
            f"disagree: {startup_native_thread_id} != "
            f"{startup_windows_thread_id}"
        )

    # If a future edit imports these before this point, fail rather than
    # silently making COM apartment selection depend on import order.
    if "pythoncom" in sys.modules or "win32com" in sys.modules:
        raise ConfigurationError(
            "pywin32 COM modules were imported before STA policy was set."
        )
    debug_print(
        "Pre-pywin32 runtime checks passed:",
        f"Python={sys.version.split()[0]}",
        f"bits={python_bits}",
        f"native_tid={startup_native_thread_id}",
        f"GIL={is_gil_enabled()}",
    )
    return python_bits, startup_native_thread_id, is_gil_enabled


# ============================================================================
# pywin32 version validation helper
# ============================================================================

def get_pywin32_version() -> str:
    """Return installed pywin32 version and enforce the validated baseline."""
    try:
        version = importlib.metadata.version("pywin32")
    except importlib.metadata.PackageNotFoundError as exc:
        raise ConfigurationError(
            "pywin32 imported, but its package version could not be "
            "determined."
        ) from exc
    match = re.match(r"^\s*(\d+)", version)
    if not match:
        raise ConfigurationError(
            f"Could not interpret pywin32 version {version!r}."
        )
    major = int(match.group(1))
    if major < MINIMUM_PYWIN32_MAJOR:
        raise ConfigurationError(
            f"pywin32 {version} is older than baseline "
            f"{MINIMUM_PYWIN32_MAJOR}."
        )
    if major > MINIMUM_PYWIN32_MAJOR:
        warning_print(
            "pywin32",
            version,
            "is newer than the initially validated baseline",
            MINIMUM_PYWIN32_MAJOR,
            "; this run therefore also acts as revalidation.",
        )
    return version


# ============================================================================
# Explicit process/runtime COM bootstrap
# ============================================================================

def bootstrap_com_runtime() -> None:
    """Establish and validate the process/runtime COM environment once.

    CHG-15 structural invariant:
        module scope declares; main() starts; this function owns runtime/COM
        initialization.  In particular, sys.coinit_flags MUST be set before
        pythoncom / win32com.client are imported.
    """
    global pythoncom
    global win32com_client
    global PYTHON_BITS
    global STARTUP_NATIVE_THREAD_ID
    global _IS_GIL_ENABLED
    global PYWIN32_VERSION
    global _COM_RUNTIME_BOOTSTRAPPED

    # This is deliberately first so every subsequent startup diagnostic uses
    # the deterministic backslashreplace policy.
    configure_diagnostic_stream_errors()

    if _COM_RUNTIME_BOOTSTRAPPED:
        raise RuntimeError(
            "COM/runtime bootstrap was requested more than once; "
            "this worker supports one bootstrap/QSF lifecycle per process."
        )

    # These checks include the load-bearing proof that pythoncom/win32com have
    # not already been imported before the STA policy is established.
    python_bits, startup_native_thread_id, is_gil_enabled = (
        perform_pre_pywin32_runtime_checks()
    )

    # Explicitly request STA BEFORE importing any pywin32 COM module.
    sys.coinit_flags = COINIT_APARTMENTTHREADED_VALUE
    debug_print(
        "Set sys.coinit_flags =",
        COINIT_APARTMENTTHREADED_VALUE,
        "(COINIT_APARTMENTTHREADED) before pywin32 import.",
    )

    try:
        import pythoncom as imported_pythoncom
        import win32com.client as imported_win32com_client
    except ImportError as exc:
        raise ConfigurationError(
            "pywin32 is not installed or could not be imported. "
            "Expected installation: python -m pip install pywin32. "
            f"Import error: {exc}"
        ) from exc

    if getattr(imported_pythoncom, "COINIT_APARTMENTTHREADED", None) != (
        COINIT_APARTMENTTHREADED_VALUE
    ):
        raise ConfigurationError(
            "Unexpected pythoncom COINIT_APARTMENTTHREADED value; "
            "COM policy requires review."
        )

    pywin32_version = get_pywin32_version()

    # Publish validated runtime state only after every bootstrap check above
    # has succeeded.  The completion flag is intentionally committed last.
    pythoncom = imported_pythoncom
    win32com_client = imported_win32com_client
    PYTHON_BITS = python_bits
    STARTUP_NATIVE_THREAD_ID = startup_native_thread_id
    _IS_GIL_ENABLED = is_gil_enabled
    PYWIN32_VERSION = pywin32_version
    _COM_RUNTIME_BOOTSTRAPPED = True


# ============================================================================
# Windows COM apartment inspection
# ============================================================================

def describe_apartment(apt_type: int) -> str:
    return {
        APTTYPE_STA: "STA",
        APTTYPE_MTA: "MTA",
        APTTYPE_NA: "Neutral Apartment",
        APTTYPE_MAINSTA: "Main STA",
    }.get(apt_type, f"Unknown ({apt_type})")

def describe_apartment_qualifier(qualifier: int) -> str:
    return {
        APTTYPEQUALIFIER_NONE: "None",
        APTTYPEQUALIFIER_IMPLICIT_MTA: "Implicit MTA",
        APTTYPEQUALIFIER_NA_ON_MTA: "NA on MTA",
        APTTYPEQUALIFIER_NA_ON_STA: "NA on STA",
        APTTYPEQUALIFIER_NA_ON_IMPLICIT_MTA: "NA on implicit MTA",
        APTTYPEQUALIFIER_NA_ON_MAINSTA: "NA on Main STA",
        APTTYPEQUALIFIER_APPLICATION_STA: "Application STA",
        APTTYPEQUALIFIER_RESERVED_1: "Reserved",
    }.get(qualifier, f"Unknown ({qualifier})")

def get_windows_com_apartment() -> tuple[int, int]:
    """Ask Windows which COM apartment the current OS thread occupies."""
    global _CACHED_GET_APARTMENT_TYPE

    apt_type = ctypes.c_int()
    apt_qualifier = ctypes.c_int()

    # resolve ole32.CoGetApartmentType once and reuse it.
    if _CACHED_GET_APARTMENT_TYPE is None:
        ole32 = ctypes.WinDLL("ole32", use_last_error=True)
        func = ole32.CoGetApartmentType
        func.argtypes = (
            ctypes.POINTER(ctypes.c_int),
            ctypes.POINTER(ctypes.c_int),
        )
        func.restype = ctypes.c_long
        _CACHED_GET_APARTMENT_TYPE = func
    hr = int(
        _CACHED_GET_APARTMENT_TYPE(
            ctypes.byref(apt_type),
            ctypes.byref(apt_qualifier),
        )
    )
    if hr < 0:
        raise RuntimeError(
            "CoGetApartmentType failed with HRESULT "
            f"0x{hr & 0xFFFFFFFF:08X}"
        )
    return apt_type.value, apt_qualifier.value

def assert_main_sta_context(stage: str) -> tuple[int, int]:
    """
    Re-prove at a named execution stage that COM activity remains on the
    original sole Python/Windows STA thread.
    """
    if not _COM_RUNTIME_BOOTSTRAPPED:
        raise RuntimeError(
            f"{stage}: COM runtime has not been bootstrapped. "
            "bootstrap_com_runtime() must complete before any COM context "
            "assertion. This is a call-ordering fault in the worker, not a "
            "thread-migration fault."
        )

    if threading.current_thread() is not threading.main_thread():
        raise OperationError(
            f"{stage}: execution is no longer on Python's main thread."
        )
    active_threads = threading.enumerate()
    if len(active_threads) != 1:
        raise OperationError(
            f"{stage}: unexpected additional Python thread(s): "
            f"{[t.name for t in active_threads]!r}"
        )
    native_id = threading.get_native_id()
    windows_id = get_current_windows_thread_id()
    if native_id != windows_id:
        raise OperationError(
            f"{stage}: Python native thread ID {native_id} differs from "
            f"Windows thread ID {windows_id}."
        )
    if native_id != STARTUP_NATIVE_THREAD_ID:
        raise OperationError(
            f"{stage}: COM work moved from startup OS thread "
            f"{STARTUP_NATIVE_THREAD_ID} to {native_id}."
        )
    apt_type, qualifier = get_windows_com_apartment()
    if apt_type not in (APTTYPE_STA, APTTYPE_MAINSTA):
        raise OperationError(
            f"{stage}: COM apartment is {describe_apartment(apt_type)}, "
            "not STA/Main STA."
        )
    return apt_type, qualifier

# ============================================================================
# General COM helpers
# ============================================================================

def describe_com_error(exc: BaseException) -> str:
    """Produce detailed diagnostics from a pywin32 COM exception."""
    parts = [repr(exc)]
    hresult = getattr(exc, "hresult", None)
    if hresult is not None:
        parts.append(f"HRESULT=0x{hresult & 0xFFFFFFFF:08X}")
    strerror = getattr(exc, "strerror", None)
    if strerror:
        parts.append(f"message={strerror!r}")
    excepinfo = getattr(exc, "excepinfo", None)
    if excepinfo:
        parts.append(f"EXCEPINFO={excepinfo!r}")
    argerror = getattr(exc, "argerror", None)
    if argerror is not None:
        parts.append(f"argerror={argerror!r}")
    return "; ".join(parts)

def require_callable(obj: Any, member_name: str) -> Any:
    """Retrieve a COM member which the audited interface requires callable."""
    member = getattr(obj, member_name)
    if not callable(member):
        raise OperationError(
            f"VideoReDo member {member_name!r} is no longer callable under "
            f"pywin32; received {type(member).__name__}: {member!r}. "
            "The COM interface must be re-audited before continuing."
        )
    return member

def com_result_reports_success(
    value: object,
    *,
    member_name: str,
) -> bool:
    """
    interpret the audited FileOpen/FileSaveAs success result narrowly.

    Measured on both installed VideoReDo versions with pywin32 312, FileOpen
    and FileSaveAs return the Python bool singleton True. Surviving VideoReDo
    automation documentation describes integer success semantics, so accept an
    integer non-zero result as defensive compatibility without accepting
    arbitrary Python truthy objects.

    IMPORTANT: bool MUST be checked before int because bool is a subclass of
    int in Python.

    IMPORTANT: do NOT apply this helper mechanically to every COM method. In
    particular, FileClose returned None on both measured VideoReDo versions;
    successful FileClose is established by the absence of a COM exception, not
    by a truthy return value.
    """
    if isinstance(value, bool):
        return value
    if isinstance(value, int):
        return value != 0
    raise OperationError(
        f"VideoReDo {member_name} returned unexpected success-result type "
        f"{type(value).__name__}: {value!r}. Expected bool or int; COM "
        "interface/marshalling should be re-audited."
    )

def read_zero_argument_member(
    obj: Any,
    member_name: str,
) -> tuple[Any, str]:
    """
    Read a no-argument Automation member without assuming whether pywin32
    exposes it as a callable method or an already-evaluated property value.
    """
    member = getattr(obj, member_name)
    if callable(member):
        return member(), "callable method"
    return member, f"property/value ({type(member).__name__})"

def sta_sleep(seconds: float) -> None:
    """
    Wait without any helper thread while pumping pending Windows/COM messages
    on the same STA thread.
    """
    deadline = time.monotonic() + max(0.0, seconds)
    while True:
        assert_main_sta_context("STA wait")
        pythoncom.PumpWaitingMessages()
        remaining = deadline - time.monotonic()
        if remaining <= 0:
            return
        time.sleep(min(0.05, remaining))

# ============================================================================
# Command-line and filesystem safety
# ============================================================================

def usage_text() -> str:
    return (
        f"Usage:\n"
        f"  python {SCRIPT_NAME} "
        f"<5|6> <input> <output> <profile> <cmdfile> <prefix> "
        f"<fallback_bitrate_bps> [timeout_minutes]\n\n"
        f"Mandatory arguments: 7\n"
        f"Optional eighth argument: timeout_minutes "
        f"(default {DEFAULT_QSF_TIMEOUT_MINUTES})"
    )

def parse_positive_integer(text: str, *, field_name: str) -> int:
    """Parse a deliberately strict positive decimal integer."""
    stripped = text.strip()
    if not re.fullmatch(r"[0-9]+", stripped):
        raise ConfigurationError(
            f"{field_name} must be a positive integer; received {text!r}"
        )
    value = int(stripped)
    if value <= 0:
        raise ConfigurationError(
            f"{field_name} must be greater than zero; received {value}"
        )
    return value

def absolute_path_from_argument(text: str) -> Path:
    """Normalize a supplied path into an absolute path."""
    # ------------------------------------------------------------------------
    # do not apply expanduser() to caller-supplied paths.
    #
    # PROBLEM ADDRESSED:
    #   The caller always passes fully-qualified paths (the batch expands them
    #   with %~f2 / %~f3 before invoking this worker), so expanduser() had no
    #   legitimate work to do. It did, however, introduce a failure mode:
    #   Path.expanduser() raises RuntimeError when a path's FIRST component
    #   begins with '~' and the '~user' form cannot be resolved to a home
    #   directory. Verified: Path("~foo.ts").expanduser() raises
    #   RuntimeError("Could not determine home directory.").
    #
    #   That RuntimeError is not a ConfigurationError, so it escapes
    #   parse_command_line() and surfaces as "UNEXPECTED INTERNAL FAILURE"
    #   with exit code 17, rather than as the clear configuration diagnostic
    #   the design intends.
    #
    #   HONEST SEVERITY: latent. Also verified, a path whose first component is
    #   not a tilde is unaffected - "C:\\a\\~temp.ts" passes through cleanly -
    #   so this is currently UNREACHABLE given the caller's %~f expansion. It is
    #   removed because it does nothing useful here, so it is pure downside.
    #
    # APPROACH:
    #   Remove the tilde expansion. Absolute-path normalisation is retained and
    #   is the only behaviour this worker actually requires.
    # ------------------------------------------------------------------------
    return Path(os.path.abspath(os.fspath(Path(text))))

def canonical_path_string(path: Path) -> str:
    """
    Produce a realpath/normalized/case-normalized string for Windows identity
    comparison.
    """
    return os.path.normcase(
        os.path.normpath(
            os.path.realpath(
                os.path.abspath(os.fspath(path))
            )
        )
    )

def same_path_or_file(a: Path, b: Path) -> bool:
    """
    Detect both textual aliases and, where both exist, filesystem aliases
    (including hard links) referring to the same file.
    """
    if canonical_path_string(a) == canonical_path_string(b):
        return True
    if a.exists() and b.exists():
        try:
            return os.path.samefile(a, b)
        except OSError as exc:
            debug_print(
                "os.path.samefile comparison failed for",
                repr(str(a)),
                repr(str(b)),
                repr(exc),
            )
    return False

def validate_path_relationships(
    input_path: Path,
    output_path: Path,
    output_cmd_path: Path,
) -> None:
    """
    Prove input/output/command paths cannot identify the same file BEFORE any
    deletion is permitted.
    """
    comparisons = (
        ("input video", input_path, "QSF output", output_path),
        ("input video", input_path, "command file", output_cmd_path),
        ("QSF output", output_path, "command file", output_cmd_path),
    )
    for left_name, left_path, right_name, right_path in comparisons:
        if same_path_or_file(left_path, right_path):
            raise ConfigurationError(
                f"Unsafe path relationship: {left_name} and {right_name} "
                f"identify the same file.\n"
                f"  {left_name}: {left_path}\n"
                f"  {right_name}: {right_path}"
            )

def validate_ascii_text(description: str, value: str) -> None:
    """Require a string to be representable exactly in strict ASCII."""
    try:
        value.encode("ascii", errors="strict")
    except UnicodeEncodeError as exc:
        raise ConfigurationError(
            f"{description} contains non-ASCII characters but the current "
            f"command-file compatibility policy is ASCII-only: {value!r}"
        ) from exc

def validate_known_cmd_value_safety(description: str, value: str) -> None:
    """
    Preflight a value already known before QSF that will later be inserted into
    the generated command file.
    """
    validate_ascii_text(description, value)
    bad = sorted({ch for ch in value if ch in UNSAFE_CMD_VALUE_CHARACTERS})
    if bad:
        raise ConfigurationError(
            f"{description} contains character(s) deliberately rejected for "
            f"safe cmd.exe use with delayed expansion: {bad!r}; "
            f"value={value!r}"
        )

def parse_command_line(argv: list[str]) -> RunConfig:
    """Parse and fully preflight the legacy-compatible worker arguments."""
    debug_print("Raw argv =", repr(argv))
    if len(argv) not in (7, 8):
        raise ConfigurationError(
            f"Expected exactly 7 mandatory arguments plus at most one "
            f"optional timeout argument; received {len(argv)}.\n"
            f"{usage_text()}"
        )
    version_text = argv[0].strip()
    if version_text not in ("5", "6"):
        raise ConfigurationError(
            f"VideoReDo version must be exactly 5 or 6; received {argv[0]!r}"
        )
    vrd_version = int(version_text)
    input_path = absolute_path_from_argument(argv[1])
    output_path = absolute_path_from_argument(argv[2])
    qsf_profile_name = argv[3].strip()
    if not qsf_profile_name:
        raise ConfigurationError("QSF profile name must not be empty.")
    output_cmd_path = absolute_path_from_argument(argv[4])
    variable_prefix = argv[5].strip()
    if not CMD_VARIABLE_PREFIX_RE.fullmatch(variable_prefix):
        raise ConfigurationError(
            "Command-variable prefix must match "
            "[A-Za-z_][A-Za-z0-9_]* ; received "
            f"{argv[5]!r}"
        )
    fallback_bitrate_bps = parse_positive_integer(
        argv[6],
        field_name="fallback ActualVideoBitrate bps",
    )
    if len(argv) == 8:
        timeout_minutes = parse_positive_integer(
            argv[7],
            field_name="QSF timeout minutes",
        )
    else:
        timeout_minutes = DEFAULT_QSF_TIMEOUT_MINUTES
        warning_print(
            "QSF timeout argument omitted; defaulting to",
            timeout_minutes,
            "minutes.",
        )
    config = RunConfig(
        vrd_version=vrd_version,
        input_path=input_path,
        output_path=output_path,
        qsf_profile_name=qsf_profile_name,
        output_cmd_path=output_cmd_path,
        variable_prefix=variable_prefix,
        fallback_bitrate_bps=fallback_bitrate_bps,
        timeout_minutes=timeout_minutes,
    )
    debug_print("Parsed RunConfig =", repr(config))
    if not config.input_path.exists():
        raise ConfigurationError(
            f"Input file does not exist: {config.input_path}"
        )
    if not config.input_path.is_file():
        raise ConfigurationError(
            f"Input path is not a regular file: {config.input_path}"
        )
    if config.output_path.exists() and config.output_path.is_dir():
        raise ConfigurationError(
            f"QSF output path is a directory: {config.output_path}"
        )
    if config.output_cmd_path.exists() and config.output_cmd_path.is_dir():
        raise ConfigurationError(
            f"Command-file path is a directory: {config.output_cmd_path}"
        )
    if not config.output_path.parent.is_dir():
        raise ConfigurationError(
            "QSF output parent directory does not exist: "
            f"{config.output_path.parent}"
        )
    if not config.output_cmd_path.parent.is_dir():
        raise ConfigurationError(
            "Command-file parent directory does not exist: "
            f"{config.output_cmd_path.parent}"
        )

    # Critical destructive-safety checks BEFORE any file deletion.
    validate_path_relationships(
        config.input_path,
        config.output_path,
        config.output_cmd_path,
    )

    # outputFile is later exported through the ASCII cmd file.  Reject unsafe
    # data before spending minutes/hours on QSF.
    validate_known_cmd_value_safety(
        "QSF output path",
        str(config.output_path),
    )
    validate_ascii_text(
        "command-variable prefix",
        config.variable_prefix,
    )
    debug_print("Command-line and path validation passed.")
    return config

# ============================================================================
# VideoReDo profile inventory / validation
# ============================================================================

def get_eligible_profiles(vrd: Any, version: int) -> list[str]:
    """
    Enumerate eligible output profiles using version-specific behaviour proven
    during the non-destructive COM audit.

    v5:
        ProfilesGetProfileIsAdScan is absent.  As the existing VBS did in its
        normal v5 path, all returned profiles are eligible for exact-name
        matching.

    v6:
        ProfilesGetProfileIsAdScan exists; AdScan profiles are excluded.
    """
    debug_print("Enumerating VideoReDo profiles for version", version)
    try:
        raw_count, exposure = read_zero_argument_member(vrd, "ProfilesGetCount")
    except pythoncom.com_error as exc:
        raise OperationError(
            "ProfilesGetCount COM failure: " + describe_com_error(exc)
        ) from exc
    try:
        profile_count = int(raw_count)
    except (TypeError, ValueError) as exc:
        raise OperationError(
            f"ProfilesGetCount returned non-integer value {raw_count!r}"
        ) from exc
    debug_print(
        "ProfilesGetCount returned",
        profile_count,
        "via",
        exposure,
    )
    if profile_count < 1:
        raise OperationError("VideoReDo returned zero output profiles.")
    get_name = require_callable(vrd, "ProfilesGetProfileName")
    get_is_adscan = None
    if version == 6:
        get_is_adscan = require_callable(vrd, "ProfilesGetProfileIsAdScan")
    eligible: list[str] = []
    for index in range(profile_count):
        try:
            name = str(get_name(index))
            if version == 6:
                is_adscan = bool(get_is_adscan(index))
                debug_print(
                    f"Profile[{index}] name={name!r} is_adscan={is_adscan}"
                )
                if is_adscan:
                    continue
            else:
                debug_print(
                    f"Profile[{index}] name={name!r} "
                    "(v5: all returned profiles eligible)"
                )

            eligible.append(name)
        except pythoncom.com_error as exc:
            raise OperationError(
                f"Profile enumeration COM failure at index {index}: "
                f"{describe_com_error(exc)}"
            ) from exc
    debug_print(
        f"Eligible profile count for v{version} = {len(eligible)}"
    )
    if not eligible:
        raise OperationError(
            f"VideoReDo v{version} returned no eligible QSF/output profiles."
        )
    return eligible

def validate_requested_profile(vrd: Any, config: RunConfig) -> None:
    """
    Require exact profile-name equality before any media/output file is touched.

    Selecting the appropriate codec/profile remains the CALLER's job.
    """
    eligible = get_eligible_profiles(vrd, config.vrd_version)
    if config.qsf_profile_name not in eligible:
        lines = [
            (
                f"Requested profile {config.qsf_profile_name!r} was not found "
                f"among eligible VideoReDo v{config.vrd_version} profiles."
            ),
            "Eligible profiles:",
        ]
        lines.extend(f"  {name}" for name in eligible)
        raise ConfigurationError("\n".join(lines))
    status_print(
        "PASS: exact requested VideoReDo profile exists:",
        repr(config.qsf_profile_name),
    )
    debug_print("Requested profile validation passed.")

# ============================================================================
# Safe stale-output preparation
# ============================================================================

def remove_file_if_present(path: Path, *, description: str) -> None:
    """Remove one stale regular file after all non-destructive preflight."""
    if not path.exists():
        debug_print(description, "does not already exist:", repr(str(path)))
        return
    if not path.is_file():
        raise ConfigurationError(
            f"{description} exists but is not a regular file: {path}"
        )
    debug_print(
        "Removing existing",
        description,
        "after successful preflight:",
        repr(str(path)),
    )
    try:
        path.unlink()
    except OSError as exc:
        raise ConfigurationError(
            f"Could not delete existing {description}: {path}: {exc}"
        ) from exc
    if path.exists():
        raise ConfigurationError(
            f"{description} still exists after deletion attempt: {path}"
        )

def prepare_outputs_after_preflight(config: RunConfig) -> None:
    """
    Remove stale QSF/cmd outputs only AFTER runtime, COM activation, and exact
    requested-profile validation have succeeded.

    The stale command file is removed before QSF so a failed new attempt can
    never leave an old command file that the caller could mistake for success.
    """
    status_print("Preparing output paths after successful preflight checks...")
    remove_file_if_present(
        config.output_path,
        description="QSF output file",
    )
    remove_file_if_present(
        config.output_cmd_path,
        description="QSF command file",
    )

# ============================================================================
# Output state / progress helpers
# ============================================================================

def read_output_state(vrd: Any, stage: str) -> int:
    """
    Read OutputGetState and require a genuine integer result.

    A COM/state-read failure can never be allowed to masquerade as state 0.
    """
    try:
        raw_state, exposure = read_zero_argument_member(vrd, "OutputGetState")
    except pythoncom.com_error as exc:
        raise OperationError(
            f"{stage}: OutputGetState COM failure: {describe_com_error(exc)}"
        ) from exc
    except Exception as exc:
        raise OperationError(
            f"{stage}: OutputGetState failed: {type(exc).__name__}: {exc}"
        ) from exc
    try:
        state = int(raw_state)
    except (TypeError, ValueError) as exc:
        raise OperationError(
            f"{stage}: OutputGetState returned non-integer {raw_state!r}"
        ) from exc
    debug_print(f"{stage}: OutputGetState={state} exposure={exposure}")
    return state

def read_percent_for_diagnostics(vrd: Any, stage: str) -> float | None:
    """
    Read OutputGetPercentComplete for diagnostics only.

    A percent failure is reported but does not terminate QSF while the
    authoritative OutputGetState remains readable.
    """
    try:
        raw_percent, exposure = read_zero_argument_member(
            vrd,
            "OutputGetPercentComplete",
        )
        percent = float(raw_percent)
        debug_print(
            f"{stage}: OutputGetPercentComplete={percent!r} "
            f"exposure={exposure}"
        )
        return percent
    except Exception as exc:
        # --------------------------------------------------------------------
        # report the percent-read failure once per run.
        #
        # PROBLEM ADDRESSED:
        #   This function is called on every poll (every 2 seconds). If
        #   OutputGetPercentComplete is permanently unavailable - which the
        #   surrounding code explicitly tolerates, since percent is diagnostic
        #   only - the original emitted a multi-line warning AND a full
        #   traceback every 2 seconds for the entire QSF. A four-hour run would
        #   append roughly 7,200 identical warning-plus-traceback blocks to the
        #   caller's shared log, burying the genuine diagnostics this worker
        #   exists to produce.
        #
        #   CORRECTION vs the first draft of this change: the traceback must be
        #   suppressed on repeat as well. Suppressing only the warning while
        #   still calling traceback.format_exc() every poll leaves almost all of
        #   the log volume in place and defeats the purpose of the change.
        #
        # APPROACH:
        #   First failure: warning plus full traceback, so the cause is fully
        #   diagnosable. Every subsequent failure: one concise debug line, no
        #   traceback. No control flow changes; percent remains optional and
        #   never authoritative.
        #
        #   Percent being unreliable is not hypothetical. Measured on this
        #   machine: percent reads 0, reaches ~99.9939% within about four
        #   seconds of a 47-second job, holds there for the remainder, then
        #   reads 0.0 at completion. It is not a progress indicator and must
        #   never be treated as a completion signal.
        # --------------------------------------------------------------------
        global PERCENT_READ_WARNING_EMITTED
        if not PERCENT_READ_WARNING_EMITTED:
            PERCENT_READ_WARNING_EMITTED = True
            warning_print(
                f"{stage}: could not read OutputGetPercentComplete; "
                "continuing because percent is diagnostic only. This is "
                "reported ONCE per run; further occurrences are logged as a "
                "single debug line with no traceback:",
                f"{type(exc).__name__}: {exc}",
            )
            debug_print(
                f"{stage}: percent-read traceback (first failure only):",
                traceback.format_exc(),
            )
        else:
            debug_print(
                f"{stage}: OutputGetPercentComplete still unreadable:",
                f"{type(exc).__name__}: {exc}",
            )
        return None

def observe_output_state(vrd: Any, stage: str) -> None:
    """
    Snapshot state/percent around important transitions.

    Idle state is deliberately not interpreted because v5 and v6 differ.
    """
    state = read_output_state(vrd, stage)
    percent = read_percent_for_diagnostics(vrd, stage)
    status_print(
        f"STATE [{stage}]:",
        f"OutputGetState={state}",
        (
            f"OutputGetPercentComplete={percent:g}%"
            if percent is not None
            else "OutputGetPercentComplete=<unavailable>"
        ),
    )

# ============================================================================
# Completion XML retrieval and parsing
# ============================================================================

def canonical_output_identity(path_text: str | os.PathLike[str]) -> str:
    """Canonical form used to compare completion XML outputFile identity."""
    return canonical_path_string(
        Path(os.path.abspath(os.fspath(path_text)))
    )

def parse_completion_xml(xml_text: str) -> tuple[ET.Element, str]:
    """
    Parse and minimally validate completion XML.

    Optional result nodes are intentionally NOT required here.
    """
    try:
        root = ET.fromstring(xml_text)
    except ET.ParseError as exc:
        raise ValueError(f"malformed completion XML: {exc}") from exc
    if root.tag != "VRDOutputInfo":
        raise ValueError(
            f"unexpected XML root {root.tag!r}; expected 'VRDOutputInfo'"
        )
    output_file = root.attrib.get("outputFile", "").strip()
    if not output_file:
        raise ValueError(
            "VRDOutputInfo has no usable outputFile attribute"
        )
    return root, output_file

def retrieve_matching_completion_xml(
    vrd: Any,
    config: RunConfig,
) -> tuple[str, ET.Element]:
    """
    Retrieve and validate OutputGetCompletedInfo BEFORE FileClose.

    Retry on:
        * COM failure
        * empty result
        * malformed XML
        * wrong root
        * missing outputFile
        * stale/different outputFile
    """
    assert_main_sta_context("before OutputGetCompletedInfo retrieval")
    expected_identity = canonical_output_identity(config.output_path)
    deadline = time.monotonic() + COMPLETED_INFO_MAX_WAIT_SECONDS
    attempt = 0
    last_problem = "no attempt made"

    # Preserve the legacy initial 100 ms delay.
    sta_sleep(COMPLETED_INFO_RETRY_DELAY_SECONDS)
    while True:
        attempt += 1
        debug_print(
            f"OutputGetCompletedInfo attempt {attempt}; expected=",
            repr(expected_identity),
        )
        try:
            raw, exposure = read_zero_argument_member(
                vrd,
                "OutputGetCompletedInfo",
            )
            xml_text = "" if raw is None else str(raw)

            debug_print(
                f"OutputGetCompletedInfo attempt {attempt}:",
                f"exposure={exposure}",
                f"length={len(xml_text)}",
                "raw=",
                repr(xml_text),
            )
            if not xml_text.strip():
                last_problem = (
                    f"attempt {attempt}: empty completion information"
                )
            else:
                try:
                    root, output_file = parse_completion_xml(xml_text)
                    actual_identity = canonical_output_identity(output_file)
                    debug_print(
                        f"Completion XML attempt {attempt}:",
                        "outputFile=",
                        repr(output_file),
                        "canonical=",
                        repr(actual_identity),
                    )
                    if actual_identity == expected_identity:
                        status_print(
                            "PASS: matching OutputGetCompletedInfo received",
                            f"on attempt {attempt}.",
                        )
                        return xml_text, root
                    last_problem = (
                        f"attempt {attempt}: completion information belongs "
                        f"to stale/different outputFile {output_file!r}"
                    )
                except ValueError as exc:
                    last_problem = f"attempt {attempt}: {exc}"
        except pythoncom.com_error as exc:
            last_problem = (
                f"attempt {attempt}: COM failure: {describe_com_error(exc)}"
            )
        except Exception as exc:
            last_problem = (
                f"attempt {attempt}: {type(exc).__name__}: {exc}"
            )
        debug_print("Completion-info retry condition:", last_problem)
        if time.monotonic() >= deadline:
            raise OperationError(
                "Timed out waiting for usable completion information "
                f"belonging to this QSF output; {last_problem}"
            )
        sta_sleep(COMPLETED_INFO_RETRY_DELAY_SECONDS)

def optional_xml_text(root: ET.Element, field_name: str) -> str | None:
    """Return stripped optional VRDOutputInfo child text, or None."""
    node = root.find(field_name)
    if node is None:
        debug_print(f"Optional XML field {field_name!r} is absent.")
        return None
    text = "" if node.text is None else node.text.strip()
    if not text:
        debug_print(f"Optional XML field {field_name!r} is blank.")
        return None
    debug_print(f"Optional XML field {field_name!r} = {text!r}")
    return text

# ============================================================================
# ActualVideoBitrate interpretation
# ============================================================================

def decimal_to_integer_half_even(value: Decimal) -> int:
    """Round Decimal to int using round-half-to-even."""
    return int(value.to_integral_value(rounding=ROUND_HALF_EVEN))

def declared_bitrate_multiplier(node: ET.Element) -> tuple[int, str] | None:
    """
    helper: recover a bitrate unit declared by VideoReDo in val_format.

    Returns (multiplier_to_bps, evidence_string), or None when val_format is
    absent or does not contain a recognized standalone bitrate-unit token.
    Returning None is a NORMAL compatibility outcome: the caller then uses the
    existing magnitude heuristic.
    """
    raw = node.attrib.get(VRD_BITRATE_UNIT_ATTRIBUTE)
    if not raw:
        return None
    match = VRD_DECLARED_BITRATE_UNIT_RE.search(raw)
    if match is None:
        return None
    token = match.group(1).lower()
    multiplier = VRD_DECLARED_BITRATE_MULTIPLIERS[token]
    return (
        multiplier,
        f"{VRD_BITRATE_UNIT_ATTRIBUTE}={raw!r} declares {token}",
    )

def interpret_actual_video_bitrate_bps(
    root: ET.Element,
    fallback_bps: int,
) -> tuple[int, str]:
    """
    Interpret VideoReDo's optional ActualVideoBitrate defensively.

    Returns:
        (final bitrate in bps, explanatory source string)

    CHG-10: prefer the unit VideoReDo itself declares on the element. Fall back
    to the previous magnitude heuristic only when no usable declaration exists.
    ABSENCE OF THE FIELD ENTIRELY remains a normal, expected outcome and is
    handled first, exactly as before.
    """
    # ------------------------------------------------------------------------
    # PROBLEM ADDRESSED:
    #   The original guessed the unit from the magnitude of the number:
    #     value <= 30                      -> treat as Mbps, multiply by 1e6
    #     50,000 <= value <= 30,000,000    -> treat as already-bps
    #     anything between 30 and 50,000   -> AMBIGUOUS, silently discarded in
    #                                         favour of the caller fallback
    #
    #   That dead zone is a real hazard: a value legitimately reported in kbps
    #   (about 1,931 for this material) would fall in it, and the real
    #   measurement would be thrown away in favour of an estimate, with only a
    #   warning to show for it.
    #
    #   Measurement removes the need to guess. On BOTH installed versions the
    #   element declares its own unit:
    #       val_format="%0.2f Mbps"   val_type="float"
    #   and both returned "1.931474" for the same material. The unit is stated,
    #   not implied.
    #
    # APPROACH:
    #   1. Field absent or blank  -> caller fallback. UNCHANGED. This is the
    #      normal case whenever VideoReDo omits the field, which it is known to
    #      do, and it must stay cheap and quiet rather than exceptional.
    #   2. Field present but nonnumeric or nonpositive -> caller fallback.
    #      UNCHANGED.
    #   3. Field present, numeric, and VideoReDo declares a recognized unit ->
    #      convert using the DECLARED unit, then sanity-check the result. If
    #      explicit metadata produces an implausible value, use the CALLER
    #      FALLBACK directly. Do NOT discard explicit metadata and silently
    #      reinterpret the same number using a different inferred unit.
    #   4. Field present, numeric, but no usable declared unit -> fall back to
    #      the previous magnitude heuristic, including its deliberate dead zone.
    #
    #   The heuristic is deliberately retained rather than deleted. It is now
    #   the second line of defence instead of the first, so no behaviour is
    #   lost for any XML shape that does not carry a unit declaration.
    # ------------------------------------------------------------------------
    node = root.find("ActualVideoBitrate")
    if node is None:
        debug_print("Optional XML field 'ActualVideoBitrate' is absent.")
        warning_print(
            "VideoReDo did not provide ActualVideoBitrate; using caller "
            "fallback",
            fallback_bps,
            "bps.",
        )
        return fallback_bps, "caller fallback: XML field missing/blank"
    raw_text = "" if node.text is None else node.text.strip()
    if not raw_text:
        debug_print("Optional XML field 'ActualVideoBitrate' is blank.")
        warning_print(
            "VideoReDo did not provide ActualVideoBitrate; using caller "
            "fallback",
            fallback_bps,
            "bps.",
        )
        return fallback_bps, "caller fallback: XML field missing/blank"
    debug_print(f"Optional XML field 'ActualVideoBitrate' = {raw_text!r}")
    debug_print("ActualVideoBitrate attributes =", repr(dict(node.attrib)))
    try:
        raw_value = Decimal(raw_text)
    except InvalidOperation:
        warning_print(
            "VideoReDo ActualVideoBitrate is nonnumeric:",
            repr(raw_text),
            "; using caller fallback",
            fallback_bps,
            "bps.",
        )
        return fallback_bps, "caller fallback: XML field nonnumeric"
    if not raw_value.is_finite() or raw_value <= 0:
        warning_print(
            "VideoReDo ActualVideoBitrate is nonpositive/nonfinite:",
            repr(raw_text),
            "; using caller fallback",
            fallback_bps,
            "bps.",
        )
        return fallback_bps, "caller fallback: invalid numeric value"
    declared = declared_bitrate_multiplier(node)
    if declared is not None:
        multiplier, evidence = declared
        candidate = decimal_to_integer_half_even(
            raw_value * Decimal(multiplier)
        )
        if 0 < candidate <= VRD_BITRATE_MAX_EXPECTED_BPS:
            debug_print(
                "ActualVideoBitrate",
                repr(raw_text),
                "converted using VideoReDo's declared unit ->",
                candidate,
                f"bps ({evidence}).",
            )
            return candidate, f"VideoReDo declared unit ({evidence})"
        warning_print(
            "VideoReDo declared a bitrate unit but the converted value is "
            "implausible for this documented workflow; using caller fallback "
            "rather than contradicting explicit metadata. value=",
            repr(raw_text),
            "converted=",
            candidate,
            f"({evidence}); fallback=",
            fallback_bps,
            "bps.",
        )
        return (
            fallback_bps,
            "caller fallback: declared unit produced implausible bitrate",
        )

    # No usable declared unit: use the original magnitude heuristic unchanged.
    if raw_value <= VRD_BITRATE_MAX_EXPECTED_MBPS:
        bps = decimal_to_integer_half_even(
            raw_value * Decimal(1_000_000)
        )
        debug_print(
            "ActualVideoBitrate",
            repr(raw_text),
            "interpreted as Mbps ->",
            bps,
            "bps.",
        )
        return bps, "VideoReDo value interpreted as Mbps (no declared unit)"
    if (
        raw_value >= VRD_BITRATE_MIN_PLAUSIBLE_ALREADY_BPS
        and raw_value <= VRD_BITRATE_MAX_EXPECTED_BPS
    ):
        bps = decimal_to_integer_half_even(raw_value)
        debug_print(
            "ActualVideoBitrate",
            repr(raw_text),
            "interpreted as already-bps ->",
            bps,
            "bps.",
        )
        return bps, (
            "VideoReDo value interpreted as already-bps (no declared unit)"
        )
    warning_print(
        "VideoReDo ActualVideoBitrate is ambiguous/outside documented "
        "expected ranges:",
        repr(raw_text),
        "; using caller fallback",
        fallback_bps,
        "bps.",
    )
    return fallback_bps, "caller fallback: ambiguous/out-of-range XML value"

# ============================================================================
# Normalize VideoReDo result values
# ============================================================================

def build_result_variables(
    root: ET.Element,
    config: RunConfig,
) -> dict[str, str]:
    """
    Build the unprefixed key/value dictionary exported to cmd.exe.

    Missing optional fields remain absent.  The generated command file first
    clears ALL old variables using the chosen prefix, so omission cannot leave
    a stale value from an earlier run.
    """
    result: dict[str, str] = {}
    output_file = root.attrib.get("outputFile", "").strip()
    if not output_file:
        # Defence in depth; parse_completion_xml already enforces this.
        raise OperationError(
            "Completion XML unexpectedly lacks required outputFile."
        )
    result["outputFile"] = output_file
    for field_name in OPTIONAL_XML_FIELDS:
        value = optional_xml_text(root, field_name)
        if value is None:
            warning_print(
                f"VideoReDo completion XML did not provide optional field "
                f"{field_name!r}; corresponding environment variable will "
                "remain unset."
            )
            continue
        result[field_name] = value
    bitrate_bps, bitrate_source = interpret_actual_video_bitrate_bps(
        root,
        config.fallback_bitrate_bps,
    )
    result["ActualVideoBitrate"] = str(bitrate_bps)
    debug_print(
        "Final ActualVideoBitrate =",
        bitrate_bps,
        "bps; source =",
        bitrate_source,
    )
    debug_print("Normalized QSF result dictionary =", repr(result))
    return result

# ============================================================================
# Generated BAT/CMD safety and atomic writing
# ============================================================================

def validate_cmd_value(variable_name: str, value: str) -> None:
    """
    Validate one value to be inserted literally into:
        @SET "NAME=value"

    The caller uses delayed expansion.  Rather than invent clever escaping
    during the migration, reject data whose cmd.exe interpretation is unsafe
    or insufficiently proven.
    """
    try:
        value.encode("ascii", errors="strict")
    except UnicodeEncodeError as exc:
        raise OperationError(
            f"Value for generated variable {variable_name!r} is not ASCII "
            f"under the current compatibility policy: {value!r}"
        ) from exc
    bad = sorted({ch for ch in value if ch in UNSAFE_CMD_VALUE_CHARACTERS})
    if bad:
        raise OperationError(
            f"Value for generated variable {variable_name!r} contains "
            f"character(s) rejected for safe cmd.exe/delayed-expansion use: "
            f"{bad!r}; value={value!r}"
        )

def build_command_file_bytes(
    variables: dict[str, str],
    prefix: str,
) -> bytes:
    """
    Build strict-ASCII CRLF command-file bytes.

    Each command suppresses only its own echo using '@'.  Global ECHO state is
    untouched.
    """
    lines: list[str] = []
    lines.append("@REM ---")
    lines.append(f"@REM Generated by {SCRIPT_NAME} {SCRIPT_VERSION}")
    lines.append(
        f"@REM Clear existing variables beginning with prefix {prefix}"
    )

    # SET prefix returns nonzero when no match exists; suppress that harmless
    # diagnostic inside FOR /F.
    # The leading @ suppresses echo of the FOR command itself.  The @ before
    # SET is also required because, when the caller has ECHO ON, cmd.exe echoes
    # each command executed by the DO body unless that individual command also
    # suppresses its own echo.
    # This lets the generated command file remain completely neutral about the
    # caller's global ECHO state.
    lines.append(
        f'@FOR /F "tokens=1,* delims==" %%G IN '
        f"('SET {prefix} 2^>NUL') DO @SET \"%%G=\""
    )
    lines.append("@REM ---")
    for key, value in variables.items():
        variable_name = f"{prefix}{key}"

        if not CMD_VARIABLE_PREFIX_RE.fullmatch(variable_name):
            raise OperationError(
                f"Generated environment-variable name is unsafe: "
                f"{variable_name!r}"
            )
        validate_cmd_value(variable_name, value)
        lines.append(f'@SET "{variable_name}={value}"')
    lines.append("@REM ---")
    lines.append("@GOTO :EOF")
    text = "\r\n".join(lines) + "\r\n"
    try:
        return text.encode("ascii", errors="strict")
    except UnicodeEncodeError as exc:
        raise OperationError(
            "Generated command file unexpectedly contains non-ASCII data."
        ) from exc

def write_command_file_atomically(final_path: Path, data: bytes) -> None:
    """
    Write the result command file via an fsynced sibling temporary file and
    atomic os.replace().
    """
    temp_name: str | None = None

    debug_print(
        "Atomic command-file write:",
        "final=",
        repr(str(final_path)),
        "bytes=",
        len(data),
    )
    try:
        with tempfile.NamedTemporaryFile(
            mode="wb",
            dir=final_path.parent,
            prefix=final_path.name + ".tmp.",
            suffix=".bat",
            delete=False,
        ) as handle:
            temp_name = handle.name
            debug_print("Writing temporary command file", repr(temp_name))

            handle.write(data)
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temp_name, final_path)
        debug_print(
            "Atomic os.replace completed:",
            repr(temp_name),
            "->",
            repr(str(final_path)),
        )
    except Exception as exc:
        if temp_name is not None:
            try:
                Path(temp_name).unlink(missing_ok=True)
            except Exception as cleanup_exc:
                warning_print(
                    "Could not remove temporary command file after write "
                    "failure:",
                    repr(temp_name),
                    f"{type(cleanup_exc).__name__}: {cleanup_exc}",
                )
        raise OperationError(
            f"Could not create final QSF command file {final_path}: "
            f"{type(exc).__name__}: {exc}"
        ) from exc
    if not final_path.is_file():
        raise OperationError(
            "Atomic command-file write returned but final file does not "
            f"exist: {final_path}"
        )
    if final_path.stat().st_size <= 0:
        raise OperationError(
            f"Generated command file is empty: {final_path}"
        )

# ============================================================================
# Final QSF output proof
# ============================================================================

def validate_completed_output_file(config: RunConfig) -> int:
    """Require completed QSF output to exist as a non-empty regular file."""
    if not config.output_path.is_file():
        raise OperationError(
            "VideoReDo reported QSF completion but output does not exist as "
            f"a regular file: {config.output_path}"
        )
    try:
        size = config.output_path.stat().st_size
    except OSError as exc:
        raise OperationError(
            f"Could not stat completed QSF output {config.output_path}: {exc}"
        ) from exc
    if size <= 0:
        raise OperationError(
            f"Completed QSF output is zero bytes: {config.output_path}"
        )
    debug_print(
        "Completed output validation:",
        repr(str(config.output_path)),
        "size_bytes=",
        size,
    )
    return size

# ============================================================================
# Best-effort cleanup preserving the primary failure
# ============================================================================

def best_effort_cleanup(
    *,
    vrd: Any,
    silent: Any,
    file_opened: bool,
    file_close_attempted: bool,
    program_exit_attempted: bool,
    primary_failure: BaseException | None,
) -> tuple[Any, Any]:
    """
    Attempt cleanup once while keeping the ORIGINAL failure authoritative.

    If OutputGetState or another COM operation fails because VideoReDo has
    disappeared, FileClose and ProgramExit may naturally fail as well.  Those
    cleanup failures are warnings only and never replace the original error.

    No cleanup call is retried.  If a cleanup COM call itself hangs, the outer
    batch watchdog remains the final safety mechanism.
    """
    debug_print(
        "Entering best_effort_cleanup:",
        f"file_opened={file_opened}",
        f"file_close_attempted={file_close_attempted}",
        f"program_exit_attempted={program_exit_attempted}",
        "primary_failure=",
        repr(primary_failure),
    )
    if vrd is not None and file_opened and not file_close_attempted:
        try:
            assert_main_sta_context("cleanup before FileClose")
            debug_print("Cleanup: attempting FileClose() once.")
            close_result = require_callable(vrd, "FileClose")()
            debug_print(
                "Cleanup FileClose returned",
                repr(close_result),
                "type=",
                type(close_result).__name__,
            )
        except Exception as exc:
            warning_print(
                "Cleanup FileClose() failed; preserving original failure "
                "and proceeding:",
                f"{type(exc).__name__}: {exc}",
            )
            debug_print("Cleanup FileClose traceback:", traceback.format_exc())
    if vrd is not None and not program_exit_attempted:
        try:
            assert_main_sta_context("cleanup before ProgramExit")
            debug_print("Cleanup: attempting ProgramExit() once.")
            exit_result = require_callable(vrd, "ProgramExit")()
            debug_print(
                "Cleanup ProgramExit returned",
                repr(exit_result),
                "type=",
                type(exit_result).__name__,
            )
        except Exception as exc:
            warning_print(
                "Cleanup ProgramExit() failed; preserving original failure:",
                f"{type(exc).__name__}: {exc}",
            )
            debug_print(
                "Cleanup ProgramExit traceback:",
                traceback.format_exc(),
            )

    # ------------------------------------------------------------------------
    # do not orphan a VideoReDo process when VRDInterface was never obtained.
    #
    # PROBLEM ADDRESSED:
    #   Every cleanup branch above is gated on 'vrd is not None'. If
    #   DispatchEx() succeeds but retrieving silent.VRDInterface then fails,
    #   'silent' holds a live out-of-process VideoReDo automation server while
    #   'vrd' is still None. All cleanup was skipped, the reference was simply
    #   dropped, and ProgramExit() was never called.
    #
    #   HONEST FRAMING: this is defensive hardening, not a proven leak. It has
    #   not been demonstrated that releasing the final COM proxy leaves an
    #   orphaned process. But VideoReDo's documented shutdown path is
    #   ProgramExit(), and relying on undocumented final-reference behaviour is
    #   not something this workflow has ever established.
    #
    #   It matters more than it looks because the caller's batch retries with
    #   the OTHER VideoReDo version on failure, so a leak on this path would
    #   accumulate across the fallback and across successive recordings.
    #
    # APPROACH:
    #   Make ONE best-effort attempt to reach ProgramExit through the silent
    #   wrapper. If that is not possible, say so explicitly in the log so the
    #   operator knows a stray VideoReDo process may need killing, rather than
    #   leaving it undiagnosable. As with every other cleanup action here,
    #   failure is a warning only and never replaces the original error, and no
    #   action is ever retried.
    # ------------------------------------------------------------------------
    if vrd is None and silent is not None and not program_exit_attempted:
        try:
            assert_main_sta_context("cleanup before fallback ProgramExit")
            debug_print(
                "Cleanup: VRDInterface was never obtained; attempting "
                "ProgramExit() once through the silent wrapper."
            )
            fallback_interface = silent.VRDInterface
            exit_result = require_callable(fallback_interface, "ProgramExit")()
            debug_print(
                "Cleanup fallback ProgramExit returned",
                repr(exit_result),
                "type=",
                type(exit_result).__name__,
            )
            fallback_interface = None
        except Exception as exc:
            warning_print(
                "Cleanup could not reach ProgramExit() via the silent "
                "wrapper. A VideoReDo automation process may still be "
                "running and may require manual termination:",
                f"{type(exc).__name__}: {exc}",
            )
            debug_print(
                "Cleanup fallback ProgramExit traceback:",
                traceback.format_exc(),
            )

    # Release Python COM proxies on this same main STA thread.
    vrd = None
    silent = None
    try:
        gc.collect()
    except Exception as exc:
        warning_print(
            "gc.collect() during cleanup raised:",
            f"{type(exc).__name__}: {exc}",
        )
    try:
        assert_main_sta_context("after COM proxy release")
    except Exception as exc:
        warning_print(
            "Final STA/thread invariant check failed during cleanup:",
            f"{type(exc).__name__}: {exc}",
        )
    debug_print("best_effort_cleanup complete.")
    return vrd, silent

# ============================================================================
# One complete VideoReDo QSF attempt
# ============================================================================

def perform_videoredo_qsf(config: RunConfig) -> dict[str, str]:
    """
    Own the complete COM lifecycle for ONE VideoReDo QSF attempt.
    """
    silent = None
    vrd = None
    file_opened = False
    file_close_attempted = False
    program_exit_attempted = False
    primary_failure: BaseException | None = None
    try:
        apt_type, qualifier = assert_main_sta_context(
            "before VideoReDo activation"
        )
        debug_print(
            "COM context before activation:",
            f"apartment={describe_apartment(apt_type)}",
            f"qualifier={describe_apartment_qualifier(qualifier)}",
        )

        # --------------------------------------------------------------------
        # COM server activation / interface acquisition.
        # --------------------------------------------------------------------
        status_print(
            f"Creating VideoReDo v{config.vrd_version} COM server..."
        )
        debug_print("DispatchEx ProgID =", repr(config.progid))
        try:
            silent = win32com_client.DispatchEx(config.progid)
        except pythoncom.com_error as exc:
            raise OperationError(
                "Could not create VideoReDo COM server: "
                f"{describe_com_error(exc)}"
            ) from exc
        except Exception as exc:
            raise OperationError(
                "Could not create VideoReDo COM server: "
                f"{type(exc).__name__}: {exc}"
            ) from exc
        status_print("PASS: VideoReDoSilent COM server created")
        assert_main_sta_context("after VideoReDo activation")
        try:
            vrd = silent.VRDInterface
        except pythoncom.com_error as exc:
            raise OperationError(
                "Could not retrieve VRDInterface: "
                f"{describe_com_error(exc)}"
            ) from exc
        except Exception as exc:
            raise OperationError(
                f"Could not retrieve VRDInterface: "
                f"{type(exc).__name__}: {exc}"
            ) from exc
        status_print("PASS: VRDInterface retrieved")
        debug_print("VRDInterface proxy type =", type(vrd).__name__)
        assert_main_sta_context("after VRDInterface retrieval")

        # Disable VideoReDo audio alert as the legacy worker did.
        try:
            debug_print("Calling ProgramSetAudioAlert(False).")
            require_callable(vrd, "ProgramSetAudioAlert")(False)
        except pythoncom.com_error as exc:
            raise OperationError(
                "ProgramSetAudioAlert(False) COM failure: "
                f"{describe_com_error(exc)}"
            ) from exc
        except Exception as exc:
            raise OperationError(
                "ProgramSetAudioAlert(False) failure: "
                f"{type(exc).__name__}: {exc}"
            ) from exc
        status_print("PASS: ProgramSetAudioAlert(False)")

        # Idle state is diagnostic only; v5 and v6 legitimately differ.
        observe_output_state(
            vrd,
            "fresh instance before profile validation",
        )

        # --------------------------------------------------------------------
        # Non-destructive profile validation BEFORE deleting any output.
        # --------------------------------------------------------------------
        validate_requested_profile(vrd, config)
        prepare_outputs_after_preflight(config)

        # --------------------------------------------------------------------
        # FileOpen(input, True): QSF mode.
        # --------------------------------------------------------------------
        assert_main_sta_context("before FileOpen")
        file_open = require_callable(vrd, "FileOpen")
        status_print("Opening input in VideoReDo QSF mode...")
        debug_print(
            "Calling FileOpen(input, True):",
            repr(str(config.input_path)),
        )
        try:
            open_result = file_open(str(config.input_path), True)
        except pythoncom.com_error as exc:
            raise OperationError(
                "VideoReDo FileOpen COM failure: "
                f"{describe_com_error(exc)}"
            ) from exc
        except Exception as exc:
            raise OperationError(
                f"VideoReDo FileOpen failure: "
                f"{type(exc).__name__}: {exc}"
            ) from exc
        debug_print(
            "FileOpen returned",
            repr(open_result),
            "type=",
            type(open_result).__name__,
        )

        # --------------------------------------------------------------------
        # --------------------------------------------------------------------
        # narrow defensive compatibility for COM success values.
        #
        # MEASURED: FileOpen and FileSaveAs return Python bool True on both
        # installed VideoReDo versions with pywin32 312. Surviving VideoReDo
        # automation documentation describes integer success semantics, so the
        # helper also accepts non-zero int values. It deliberately rejects all
        # other Python truthy types instead of weakening the contract to generic
        # truthiness.
        # --------------------------------------------------------------------
        if not com_result_reports_success(
            open_result,
            member_name="FileOpen",
        ):
            raise OperationError(
                "VideoReDo FileOpen did not report success; returned "
                f"{open_result!r} of type {type(open_result).__name__}"
            )
        file_opened = True
        status_print("PASS: VideoReDo FileOpen(input, True)")
        observe_output_state(vrd, "after FileOpen before FileSaveAs")

        # --------------------------------------------------------------------
        # FileSaveAs(output, exact supplied profile): start QSF.
        # --------------------------------------------------------------------
        assert_main_sta_context("before FileSaveAs")
        file_save_as = require_callable(vrd, "FileSaveAs")

        status_print("Starting VideoReDo QSF FileSaveAs...")
        debug_print(
            "Calling FileSaveAs:",
            "output=",
            repr(str(config.output_path)),
            "profile=",
            repr(config.qsf_profile_name),
        )
        try:
            save_result = file_save_as(
                str(config.output_path),
                config.qsf_profile_name,
            )
        except pythoncom.com_error as exc:
            raise OperationError(
                "VideoReDo FileSaveAs COM failure: "
                f"{describe_com_error(exc)}"
            ) from exc
        except Exception as exc:
            raise OperationError(
                f"VideoReDo FileSaveAs failure: "
                f"{type(exc).__name__}: {exc}"
            ) from exc
        debug_print(
            "FileSaveAs returned",
            repr(save_result),
            "type=",
            type(save_result).__name__,
        )

        # use the same narrow bool/int success contract as FileOpen.
        if not com_result_reports_success(
            save_result,
            member_name="FileSaveAs",
        ):
            raise OperationError(
                "VideoReDo FileSaveAs did not report success; returned "
                f"{save_result!r} of type {type(save_result).__name__}"
            )
        status_print("PASS: VideoReDo FileSaveAs(output, profile)")
        observe_output_state(vrd, "immediately after FileSaveAs")

        # --------------------------------------------------------------------
        # Cooperative polling timeout using actual monotonic elapsed time.
        #
        # This timer cannot interrupt a COM method that itself hangs.  The
        # outer batch hard watchdog is deliberately responsible for that.
        # --------------------------------------------------------------------
        started = time.monotonic()
        deadline = started + config.timeout_seconds
        next_status_time = started
        poll_number = 0

        status_print(
            "QSF working:",
            f"internal timeout={config.timeout_minutes} minutes",
            f"poll interval={QSF_POLL_INTERVAL_SECONDS:g} seconds",
        )
        while True:
            assert_main_sta_context("QSF polling")
            state = read_output_state(vrd, f"QSF poll {poll_number}")
            percent = read_percent_for_diagnostics(
                vrd,
                f"QSF poll {poll_number}",
            )
            now = time.monotonic()
            elapsed = now - started
            debug_print(
                "QSF poll summary:",
                f"poll={poll_number}",
                f"elapsed={elapsed:.3f}s",
                f"state={state}",
                f"percent={percent!r}",
            )
            # Experimentally proven production completion authority.
            if state == 0:
                # CHG-12: measured OutputGetPercentComplete reaches nearly
                # 100% long before v6 finishes and can reset to 0 at completion.
                # Label it explicitly as a VideoReDo diagnostic value rather
                # than presenting it as whole-job progress.
                status_print(
                    "PASS: QSF completed:",
                    f"elapsed={elapsed:.2f} seconds",
                    "OutputGetState=0",
                    (
                        f"VRD_percent_diagnostic={percent:g}%"
                        if percent is not None
                        else "VRD_percent_diagnostic=<unavailable>"
                    ),
                )
                break
            if now >= next_status_time:
                # CHG-12: this is elapsed/state status. The percent member is
                # retained only as explicitly labelled diagnostic information.
                status_print(
                    "QSF status:",
                    f"elapsed={elapsed:.1f}s",
                    f"state={state}",
                    (
                        f"VRD_percent_diagnostic={percent:g}%"
                        if percent is not None
                        else "VRD_percent_diagnostic=<unavailable>"
                    ),
                )
                next_status_time = now + PROGRESS_STATUS_INTERVAL_SECONDS
            if now >= deadline:
                raise OperationError(
                    "VideoReDo QSF internal timeout expired after "
                    f"{elapsed:.2f} seconds "
                    f"({config.timeout_minutes} minutes configured)."
                )
            poll_number += 1
            sta_sleep(QSF_POLL_INTERVAL_SECONDS)

        # --------------------------------------------------------------------
        # CRITICAL ORDERING: completion info BEFORE FileClose.
        # --------------------------------------------------------------------
        status_print(
            "Retrieving and validating OutputGetCompletedInfo BEFORE "
            "FileClose..."
        )
        xml_text, root = retrieve_matching_completion_xml(vrd, config)
        debug_print("Accepted completion XML length =", len(xml_text))
        result_variables = build_result_variables(root, config)

        # --------------------------------------------------------------------
        # Normal close/exit sequence.
        # --------------------------------------------------------------------
        status_print("Closing VideoReDo source file...")
        file_close_attempted = True
        try:
            close_result = require_callable(vrd, "FileClose")()
        except pythoncom.com_error as exc:
            raise OperationError(
                "VideoReDo FileClose COM failure after otherwise completed "
                f"QSF: {describe_com_error(exc)}"
            ) from exc
        except Exception as exc:
            raise OperationError(
                "VideoReDo FileClose failure after otherwise completed QSF: "
                f"{type(exc).__name__}: {exc}"
            ) from exc
        file_opened = False
        debug_print(
            "Normal FileClose returned",
            repr(close_result),
            "type=",
            type(close_result).__name__,
        )
        status_print("PASS: VideoReDo FileClose()")
        status_print("Requesting VideoReDo ProgramExit()...")
        program_exit_attempted = True
        try:
            exit_result = require_callable(vrd, "ProgramExit")()
        except pythoncom.com_error as exc:
            raise OperationError(
                "VideoReDo ProgramExit COM failure after otherwise completed "
                f"QSF: {describe_com_error(exc)}"
            ) from exc
        except Exception as exc:
            raise OperationError(
                "VideoReDo ProgramExit failure after otherwise completed QSF: "
                f"{type(exc).__name__}: {exc}"
            ) from exc
        debug_print(
            "Normal ProgramExit returned",
            repr(exit_result),
            "type=",
            type(exit_result).__name__,
        )
        status_print("PASS: VideoReDo ProgramExit()")
        # Release the COM proxies on the same STA thread.
        vrd = None
        silent = None
        gc.collect()
        assert_main_sta_context("after normal COM release")

        # --------------------------------------------------------------------
        # Independent filesystem proof and atomic result-command generation.
        # --------------------------------------------------------------------
        output_size = validate_completed_output_file(config)
        status_print(
            "PASS: completed QSF output exists and is non-empty:",
            f"{output_size} bytes",
        )
        command_bytes = build_command_file_bytes(
            result_variables,
            config.variable_prefix,
        )

        # The actual command file deliberately contains Windows CRLF line
        # endings.  When that CRLF text is printed through a Windows text
        # stream, Python's newline translation can turn each CRLF into
        # CR-CR-LF, which appears in the log as an extra blank line.
        # Normalize only the DEBUG display copy to LF.  command_bytes itself
        # is unchanged and is still written to disk as the intended CRLF
        # ASCII command file.
        debug_command_text = (
            command_bytes.decode("ascii").replace("\r\n", "\n")
        )
        debug_print(
            "Generated command-file ASCII text:\n"
            + debug_command_text
        )
        write_command_file_atomically(
            config.output_cmd_path,
            command_bytes,
        )
        status_print(
            "PASS: generated ASCII QSF command file:",
            str(config.output_cmd_path),
        )
        return result_variables
    except BaseException as exc:
        primary_failure = exc
        raise
    finally:
        # On normal success both references were already cleared.  On any
        # failure, attempt each still-applicable cleanup action at most once.
        if vrd is not None or silent is not None:
            vrd, silent = best_effort_cleanup(
                vrd=vrd,
                silent=silent,
                file_opened=file_opened,
                file_close_attempted=file_close_attempted,
                program_exit_attempted=program_exit_attempted,
                primary_failure=primary_failure,
            )

# ============================================================================
# Startup summary
# ============================================================================

def print_startup_summary(config: RunConfig) -> None:
    """Emit the actual runtime/configuration state before touching media."""
    apt_type, qualifier = assert_main_sta_context("startup summary")
    status_print("=" * 88)
    status_print(f"{SCRIPT_NAME} {SCRIPT_VERSION}")
    status_print("=" * 88)
    status_print("Python executable       :", sys.executable)
    status_print("Python version          :", sys.version.split()[0])
    status_print("Implementation          :", platform.python_implementation())
    status_print("Architecture            :", f"{PYTHON_BITS}-bit")
    status_print(
        "Py_GIL_DISABLED build   :",
        repr(sysconfig.get_config_var("Py_GIL_DISABLED")),
    )
    status_print("GIL enabled at runtime  :", _IS_GIL_ENABLED())
    status_print("pywin32 version         :", PYWIN32_VERSION)
    status_print("Python/Windows thread ID:", STARTUP_NATIVE_THREAD_ID)
    status_print(
        "COM apartment           :",
        f"{describe_apartment(apt_type)} "
        f"(type={apt_type}, "
        f"qualifier={describe_apartment_qualifier(qualifier)} "
        f"[{qualifier}])",
    )
    status_print("DEBUG_PRINT             :", DEBUG_PRINT)
    status_print()
    status_print("VideoReDo version       :", config.vrd_version)
    status_print("ProgID                  :", config.progid)
    status_print("Input                   :", str(config.input_path))
    status_print("Output                  :", str(config.output_path))
    status_print("Profile                 :", repr(config.qsf_profile_name))
    status_print("Output command file     :", str(config.output_cmd_path))
    status_print("Variable prefix         :", repr(config.variable_prefix))
    status_print(
        "Fallback bitrate        :",
        f"{config.fallback_bitrate_bps} bps",
    )
    status_print(
        "Internal timeout        :",
        f"{config.timeout_minutes} minutes",
    )
    status_print(
        "Poll interval           :",
        f"{QSF_POLL_INTERVAL_SECONDS:g} seconds",
    )
    status_print(
        "Completion-info window  :",
        f"{COMPLETED_INFO_MAX_WAIT_SECONDS:g} seconds",
    )
    status_print("=" * 88)
    debug_print("Startup summary completed successfully.")

# ============================================================================
# Top-level program
# ============================================================================

def main(argv: list[str]) -> int:
    """Run one complete worker invocation and return its stable exit code."""
    try:
        bootstrap_com_runtime()

        config = parse_command_line(argv)
        print_startup_summary(config)
        status_print("PASS: startup/runtime/path precondition checks")
        result_variables = perform_videoredo_qsf(config)
        status_print()
        status_print("=" * 88)
        status_print("QSF RESULT: PASS")
        status_print("=" * 88)
        for key, value in result_variables.items():
            status_print(f"{key}={value}")
        status_print("=" * 88)
        status_print("PASS:", SCRIPT_NAME, "completed successfully.")
        debug_print("Successful program exit code", EXIT_SUCCESS)
        return EXIT_SUCCESS
    except ConfigurationError as exc:
        error_print("CONFIGURATION/PRECONDITION FAILURE:", str(exc))
        debug_print("ConfigurationError traceback:", traceback.format_exc())
        return EXIT_CONFIGURATION_ERROR
    except OperationError as exc:
        error_print("VIDEOREDO/QSF OPERATION FAILURE:", str(exc))
        debug_print("OperationError traceback:", traceback.format_exc())
        return EXIT_OPERATION_ERROR
    except KeyboardInterrupt:
        error_print("Interrupted by user/console.")
        debug_print("KeyboardInterrupt traceback:", traceback.format_exc())
        return EXIT_OPERATION_ERROR
    except BaseException as exc:
        # Unexpected Python/programming/runtime problems still map to the
        # worker's operational-failure contract so the outer batch sees this
        # VideoReDo attempt as failed and can apply its normal policy.
        error_print(
            "UNEXPECTED INTERNAL FAILURE:",
            f"{type(exc).__name__}: {exc}",
        )
        debug_print("Unexpected failure traceback:", traceback.format_exc())
        return EXIT_OPERATION_ERROR

# Execute the application only when this file is run directly.
# Importing the module for inspection/tests must not run the worker.
# SystemExit propagates main()'s stable return code to cmd.exe/the caller.
if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
