@echo off

REM Define base directory
set "base_directory=%cd%\"

REM Create separate environments for each script
python -m venv "%base_directory%blip2\venv_blip2"
python -m venv "%base_directory%open_flamingo\venv_open_flamingo"
python -m venv "%base_directory%wd14\venv_wd14"
python -m venv "%base_directory%summarize\venv_summarize"

echo.
echo *****************************************************************
echo installing blip2 reqs
echo *****************************************************************
echo.
REM Install requirements for each script
call "%base_directory%blip2\venv_blip2\Scripts\activate"
cd "%base_directory%blip2"
if exist "requirements.txt" (
    pip install -r requirements.txt
)
deactivate

echo.
echo *****************************************************************
echo installing flamingo reqs
echo *****************************************************************
echo.
call "%base_directory%open_flamingo\venv_open_flamingo\Scripts\activate"
cd "%base_directory%open_flamingo"
if exist "requirements.txt" (
    pip install -r requirements.txt
)
deactivate

echo.
echo *****************************************************************
echo installing wd14 reqs
echo *****************************************************************
echo.
call "%base_directory%wd14\venv_wd14\Scripts\activate"
cd "%base_directory%wd14"
if exist "requirements.txt" (
    pip install -r requirements.txt
)
deactivate

echo.
echo *****************************************************************
echo installing summarize reqs
echo *****************************************************************
echo.
call "%base_directory%summarize\venv_summarize\Scripts\activate"
cd "%base_directory%summarize"
set "CMAKE_ARGS=-DLLAMA_CUBLAS=on"
set "FORCE_CMAKE=1"
pip install llama-cpp-python --upgrade --no-cache-dir --verbose
if exist "requirements.txt" (
    pip install -r requirements.txt
)
deactivate

exit 0