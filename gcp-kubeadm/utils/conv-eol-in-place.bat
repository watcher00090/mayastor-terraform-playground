@echo off
setlocal EnableExtensions DisableDelayedExpansion

rem // Define constants here:
set "_IFILE=%~1"  & rem // (input file; first command line argument)
set "_IEOL=0d"    & rem // (incoming line-breaks; `0d` or `0a`)
set "_OEOL=" & rem // (outgoing line-breaks; `0d`, `0a`, `0d 0a`, ``)
set "_TFILE1=%TEMP%\%~n0_%RANDOM%.hex" & rem // (first temporary file)
set "_TFILE2=%TEMP%\%~n0_%RANDOM%.tmp" & rem // (second temporary file)

rem // Verify input file:
< "%_IFILE%" rem/ || exit /B
rem // Convert input file to hexadecimal values (first temporary file):
CertUtil -f -encodehex "%_IFILE%" "%_TFILE1%" 4 > nul
rem // Write to second temporary file:
> "%_TFILE2%" (
    setlocal EnableDelayedExpansion
    rem // Read first temporary file line by line:
    for /F "usebackq delims=" %%L in ("!_TFILE1!") do (
        rem /* Store current line (hex. values), then replace line-breaks
        rem    using the given line-break codes and return result: */
        set "LINE=%%L" & echo(!LINE:%_IEOL%=%_OEOL%!
    )
    endlocal
)

rem // Remove input file:
del %_IFILE% 

rem // Convert second temporary file back to input file:
CertUtil -f -decodehex "%_TFILE2%" "%_IFILE%" 4 > nul
rem // Clean up temporary files:
del "%_TFILE1%" "%_TFILE2%"

endlocal
exit /B
