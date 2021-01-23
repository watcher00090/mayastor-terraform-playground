
set "COMMAND_STR=%~dp0\conv-eol-in-place.bat @file %~dp0\..\%FILES_DIR%"

if EXIST %FILES_DIR% (
    forfiles /p %FILES_DIR% /c "cmd /c %COMMAND_STR%"
) ELSE (
    echo "convert-to-linux-eol.bat: no files to convert, returning...."
)
