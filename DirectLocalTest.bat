@REM @echo off
setlocal enableextensions enabledelayedexpansion
cls

echo [---------------------------]
echo [-VRChat-LocalTest-Launcher-]
echo [-Author---Extr3lackLiu-----]
echo [---------------------------]

set "file=%~1"
set "file=%file:\=/%"
shift

CALL:checkIfStringContainsText "%file%" "/" RESULT
IF %RESULT%==true(
    ECHO Text Found!
) ELSE (
    echo "file must contain a slash"
    exit /b 1
)

set /a "randomid_a=10000+%random%"
set /a "randomid_b=10000+%random%"
set "randomid=%randomid_a%%randomid_b%"
set /p customid=Custom roomId(10 bits)(leave blank = random):
if not "%customid%"=="" (
    set "randomid=%customid%"
)

set /A "args=--enable-debug-gui --enable-sdk-log-levels --enable-udon-debug-logging --watch-worlds %*" 
@REM :parse_args
@REM if "%~1"=="" goto :end_parse
@REM set "args=%args% %~1"
@REM shift
@REM goto :parse_args
@REM :end_parse



if not x%args:" -vr"=%==x%args% (
    echo "-vr switch not provided, starting in non-vr mode"
    set "args=%args% --no-vr"
)
set "args=%args: -vr=%"
echo "Args: %args%"


if "%file%"=="" (
    REM Search for .vrcw file in current directory and subdirectories
    dir /s /b *.vrcw > temp.txt
    REM Read the first line from temp.txt and store it in file variable
    set /p file=<temp.txt 
    del temp.txt
)
echo "file: %file%"

set "GameDir=%~dp0"
set "GameExe=%GameDir%VRChat.exe"
echo "GameExe: %GameExe%"

set /p ClientCount=Amount of Clients to create(leave blank = 1):

if "%ClientCount%"=="" set ClientCount=1
for /l %%i in (1, 1, %ClientCount%) do (
	set "command=%GameExe% %args% --url=create?roomId=%randomid%&hidden=true&name=BuildAndRun&url=file:///%file%"
    echo "%command%"
    pause
	start "" /D %GameDir% %command%
)

:FUNCTIONS
@REM FUNCTIONS AREA (https://stackoverflow.com/a/62565139)
GOTO:EOF
EXIT /B

:checkIfStringContainsText 
@REM # CHECKS IF A STRING CONTAINS A SUBSTRING
@REM # Returns the %3 as either set to true or false
@REM # Not case sensetive by defualt. But can be set to case sensetive buying adding true as the fourth paramater
@REM # For example: CALL:checkIfStringCotainsText "Whats up SLY Fox?"   "fox"          RESULT              true
@REM #                                                 SearchText     SearchTerm 
   true-or-false    CaseSensitive?
@Rem # Will check if "Whats up SLY Fox?"" contains the text "fox"
@REM # Then check the result with: if %RESULT%==true (Echo Text Found) Else (Text Not Found)
@REM # Remember do not add %RESULT% use only RESULT .Do not add % around RESULT when calling the function.
@REM # Only add % around RESULT when checking the result.
@REM # Make sure to add "SETLOCAL ENABLEDELAYEDEXPANSION" to the top of your Batch File! This is important!
@REM # Make sure you use quotes around SearchText and SearchTerm. For example "SearchText" not SearchText.
@REM # This is because if there is a space inside the SearchText, each space will make it look like a new parameter



SET SearchString=%~1
SET SearchTerm=%~2
@REM #Check if Case Senseitive
IF [%~4]==[true] (
    @REM if %~4 is not set to anything, treat it as the default as false
    @REM - Do nothing as FindStr is normally case sensetive
) ELSE (
    @REM Change both the text and search-term both to lowercase.
    CALL:LCase SearchString SearchString
    CALL:LCase SearchTerm SearchTerm

)
@set containsText=false
@echo DEBUG: Searching for ^|%~2^| inside ^|%~1^|
@echo "!SearchString!" | find "!SearchTerm!" > nul && if errorlevel 0 (set containsText=true)
SET %3=!containsText!
@GOTO:EOF


:LCase
:UCase
@REM Converts Text to Upper or Lower Case
@REM Brad Thone robvanderwoudeDOTcom
:: Converts to upper/lower case variable contents
:: Syntax: CALL :UCase _VAR1 _VAR2
:: Syntax: CALL :LCase _VAR1 _VAR2
:: _VAR1 = Variable NAME whose VALUE is to be converted to upper/lower case
:: _VAR2 = NAME of variable to hold the converted value
:: Note: Use variable NAMES in the CALL, not values (pass "by reference")
SET _UCase=A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
SET _LCase=a b c d e f g h i j k l m n o p q r s t u v w x y z
SET _Lib_UCase_Tmp=!%1!
IF /I "%0"==":UCase" SET _Abet=%_UCase%
IF /I "%0"==":LCase" SET _Abet=%_LCase%
FOR %%Z IN (%_Abet%) DO SET _Lib_UCase_Tmp=!_Lib_UCase_Tmp:%%Z=%%Z!
SET %2=%_Lib_UCase_Tmp%
GOTO:EOF