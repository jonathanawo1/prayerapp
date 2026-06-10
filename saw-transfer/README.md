# SAW — Stock Alert Watcher

A real-time stock monitoring and alert application. SAW watches product pages for stock availability changes and sends Discord notifications when items come back in stock. **No automated purchasing — all buying is done manually by the user.**

## Quick Start

### Backend
```bash
cd backend
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
```

### Frontend
```bash
cd frontend
npm install
npm run dev
```

### Docker
```bash
docker-compose up --build
```

## Disclaimer
SAW is a monitoring and alerting tool only. It does not perform any automated purchasing.
