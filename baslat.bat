@echo off
REM Bulut'u Windows'ta baslatir
where ollama >nul 2>nul || (echo Ollama bulunamadi. https://ollama.com adresinden kurun. & pause & exit /b 1)
ollama list | findstr /i "qwen2.5-coder:7b" >nul || ollama pull qwen2.5-coder:7b
start "" http://127.0.0.1:8765
python bulut.py %*
pause
